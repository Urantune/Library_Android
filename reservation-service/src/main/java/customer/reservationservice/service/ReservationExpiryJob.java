package customer.reservationservice.service;

import customer.reservationservice.client.CatalogInventoryClient;
import customer.reservationservice.client.CirculationLoanClient;
import customer.reservationservice.dto.ReservationDtos.FulfilledLoanResult;
import customer.reservationservice.dto.ReservationDtos.ReservationResponse;
import customer.reservationservice.entity.IdempotencyRecordEntity;
import customer.reservationservice.entity.ReservationEntity;
import customer.reservationservice.entity.ReservationOperationEntity;
import customer.reservationservice.repository.ReservationOperationRepository;
import customer.reservationservice.repository.ReservationRepository;
import customer.reservationservice.repository.IdempotencyRecordRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Expires READY holds past their 24h pickup window and reconciles pending cross-service compensations.
 * Releases the exact reservation holder in Catalog so Catalog emits CopyAvailable for the next queue member.
 */
@Component
public class ReservationExpiryJob {
    private static final Logger log = LoggerFactory.getLogger(ReservationExpiryJob.class);

    private final ReservationRepository reservations;
    private final ReservationOperationRepository operations;
    private final CatalogInventoryClient catalogClient;
    private final CirculationLoanClient circulationClient;
    private final IdempotencyRecordRepository idempotencyRecords;
    private final ObjectMapper mapper;
    private final TransactionTemplate transactionTemplate;
    private final Clock clock;
    private final boolean jobsEnabled;

    public ReservationExpiryJob(
            ReservationRepository reservations,
            ReservationOperationRepository operations,
            CatalogInventoryClient catalogClient,
            CirculationLoanClient circulationClient,
            IdempotencyRecordRepository idempotencyRecords,
            ObjectMapper mapper,
            TransactionTemplate transactionTemplate,
            Clock clock,
            @Value("${app.reservation.jobs.enabled:true}") boolean jobsEnabled
    ) {
        this.reservations = reservations;
        this.operations = operations;
        this.catalogClient = catalogClient;
        this.circulationClient = circulationClient;
        this.idempotencyRecords = idempotencyRecords;
        this.mapper = mapper;
        this.transactionTemplate = transactionTemplate;
        this.clock = clock;
        this.jobsEnabled = jobsEnabled;
    }

    @Scheduled(fixedDelayString = "${app.reservation.expiry-check-ms:30000}")
    public void scheduledTick() {
        if (!jobsEnabled) {
            return;
        }
        Instant now = Instant.now(clock);
        expireReady(now);
        reconcilePendingOperations(now);
    }

    public int expireReady(Instant now) {
        String nowIso = now.toString();

        // Step 1 (Short SQLite TX): Transition READY -> EXPIRED and record release operations
        List<ExpiredReleaseTask> tasks = transactionTemplate.execute(tx -> {
            List<ReservationEntity> expiredList = reservations.findExpiredReadyReservations(nowIso);
            List<ExpiredReleaseTask> collected = new ArrayList<>();

            for (ReservationEntity entity : expiredList) {
                entity.setStatus("EXPIRED");
                entity.setExpiredAt(nowIso);
                entity.setUpdatedAt(nowIso);
                entity.setAggregateVersion(entity.getAggregateVersion() + 1);
                reservations.saveAndFlush(entity);

                if (entity.getHeldCopyId() != null && !entity.getHeldCopyId().isBlank()) {
                    String releaseOpId = ReservationQueueService.deterministicUuid("expire-release:" + entity.getId());
                    ReservationOperationEntity op = operations.findById(releaseOpId).orElseGet(() -> {
                        ReservationOperationEntity created = new ReservationOperationEntity();
                        created.setId(releaseOpId);
                        created.setReservationId(entity.getId());
                        created.setOperationType("RELEASE_EXPIRED");
                        created.setBookId(entity.getBookId());
                        created.setCopyId(entity.getHeldCopyId());
                        created.setCreatedAt(nowIso);
                        return created;
                    });
                    op.setStatus("PENDING");
                    op.setAttemptCount(op.getAttemptCount() + 1);
                    op.setUpdatedAt(nowIso);
                    operations.saveAndFlush(op);

                    collected.add(new ExpiredReleaseTask(entity.getId(), entity.getHeldCopyId(), releaseOpId));
                }
            }
            return collected;
        });

        if (tasks == null || tasks.isEmpty()) {
            return 0;
        }

        // Step 2 (OUTSIDE SQLite TX): Release each held copy in Catalog with expectedHolderId = reservationId
        String traceId = "expiry-" + UUID.randomUUID();
        for (ExpiredReleaseTask task : tasks) {
            try {
                catalogClient.releaseCopy(
                        task.copyId(),
                        task.reservationId(),
                        task.operationId(),
                        "RESERVATION_EXPIRED",
                        traceId
                );
                transactionTemplate.executeWithoutResult(tx -> operations.findById(task.operationId()).ifPresent(op -> {
                    op.setStatus("COMPLETED");
                    op.setUpdatedAt(Instant.now(clock).toString());
                    operations.saveAndFlush(op);
                }));
            } catch (RuntimeException ex) {
                log.warn("Catalog release failed for expired reservation={}; scheduling recovery retry",
                        task.reservationId(), ex);
                transactionTemplate.executeWithoutResult(tx -> operations.findById(task.operationId()).ifPresent(op -> {
                    op.setStatus("COMPENSATION_REQUIRED");
                    op.setNextRetryAt(now.plus(Duration.ofSeconds(15)).toString());
                    op.setLastError(ex.getMessage());
                    op.setUpdatedAt(now.toString());
                    operations.saveAndFlush(op);
                }));
            }
        }
        return tasks.size();
    }

    public int reconcilePendingOperations(Instant now) {
        List<ReservationOperationEntity> due = transactionTemplate.execute(tx ->
                operations.findByStatusOrderByUpdatedAtAsc("COMPENSATION_REQUIRED").stream()
                        .filter(operation -> operation.getNextRetryAt() == null
                                || !Instant.parse(operation.getNextRetryAt()).isAfter(now))
                        .toList()
        );
        if (due == null || due.isEmpty()) {
            return 0;
        }

        int recovered = 0;
        String traceId = "reconcile-" + UUID.randomUUID();
        for (ReservationOperationEntity op : due) {
            try {
                boolean fulfillmentRecovered = false;
                switch (op.getOperationType()) {
                    case "RELEASE_EXPIRED", "RELEASE_CANCEL", "CLAIM_COPY" -> {
                        String reason = "RELEASE_EXPIRED".equals(op.getOperationType())
                                ? "RESERVATION_EXPIRED"
                                : "RESERVATION_CANCELLED";
                        catalogClient.releaseCopy(
                                op.getCopyId(),
                                op.getReservationId(),
                                ReservationQueueService.deterministicUuid("reconcile-rel:" + op.getId()),
                                reason,
                                traceId
                        );
                    }
                    case "FULFILL" -> {
                        recoverFulfillment(op, traceId);
                        fulfillmentRecovered = true;
                    }
                    default -> log.warn("Unknown operation type during reconciliation: {}", op.getOperationType());
                }

                if (!fulfillmentRecovered) {
                    transactionTemplate.executeWithoutResult(tx -> operations.findById(op.getId()).ifPresent(entity -> {
                        entity.setStatus("COMPENSATED");
                        entity.setUpdatedAt(Instant.now(clock).toString());
                        operations.saveAndFlush(entity);
                    }));
                }
                recovered++;
            } catch (RuntimeException ex) {
                log.warn("Reconciliation retry failed for op={}", op.getId(), ex);
                transactionTemplate.executeWithoutResult(tx -> operations.findById(op.getId()).ifPresent(entity -> {
                    entity.setAttemptCount(entity.getAttemptCount() + 1);
                    entity.setNextRetryAt(now.plus(Duration.ofSeconds(30)).toString());
                    entity.setLastError(ex.getMessage());
                    entity.setUpdatedAt(now.toString());
                    operations.saveAndFlush(entity);
                }));
            }
        }
        return recovered;
    }

    private void recoverFulfillment(ReservationOperationEntity operation, String traceId) {
        ReservationEntity reservation = transactionTemplate.execute(
                tx -> reservations.findById(operation.getReservationId()).orElse(null));
        if (reservation == null) {
            throw new IllegalStateException("Reservation missing during fulfill recovery: " + operation.getReservationId());
        }
        if ("FULFILLED".equals(reservation.getStatus())) {
            markFulfillRecovered(operation, reservation.getFulfilledLoanId());
            return;
        }
        if (!"READY".equals(reservation.getStatus())) {
            throw new IllegalStateException("Reservation is no longer READY during fulfill recovery");
        }

        // A failed compensation means the copy was already transferred to the
        // loan holder. Retry only the reverse transfer; Circulation may still
        // be unavailable and must not be called until a later fulfill attempt.
        if (operation.getLastError() != null && operation.getLastError().contains(" | compensation error: ")) {
            catalogClient.transferCopyHolder(
                    operation.getCopyId(),
                    operation.getTargetLoanId(),
                    "RESERVATION",
                    operation.getReservationId(),
                    ReservationQueueService.deterministicUuid("recovery-comp-transfer:" + operation.getId()),
                    traceId
            );
            transactionTemplate.executeWithoutResult(tx -> operations.findById(operation.getId()).ifPresent(entity -> {
                entity.setStatus("COMPENSATED");
                entity.setUpdatedAt(Instant.now(clock).toString());
                operations.saveAndFlush(entity);
            }));
            return;
        }

        String transferOperationId = ReservationQueueService.deterministicUuid("transfer:" + operation.getId());
        catalogClient.transferCopyHolder(
                operation.getCopyId(),
                operation.getReservationId(),
                "LOAN",
                operation.getTargetLoanId(),
                transferOperationId,
                traceId
        );
        try {
            FulfilledLoanResult committedLoan = circulationClient.fulfillReservationIntoLoan(
                    operation.getTargetLoanId(),
                    operation.getReservationId(),
                    reservation.getUserId(),
                    reservation.getBookId(),
                    operation.getCopyId(),
                    operation.getActorId(),
                    ReservationQueueService.deterministicUuid("loan-commit:" + operation.getId()),
                    operation.getIdempotencyKey(),
                    traceId
            );
            markFulfillRecovered(operation, committedLoan.loanId());
        } catch (customer.reservationservice.exception.ReservationException ex) {
            if (ex.status() != org.springframework.http.HttpStatus.CONFLICT) throw ex;
            catalogClient.transferCopyHolder(
                    operation.getCopyId(),
                    operation.getTargetLoanId(),
                    "RESERVATION",
                    operation.getReservationId(),
                    ReservationQueueService.deterministicUuid("recovery-comp-transfer:" + operation.getId()),
                    traceId
            );
            transactionTemplate.executeWithoutResult(tx -> operations.findById(operation.getId()).ifPresent(entity -> {
                entity.setStatus("COMPENSATED");
                entity.setLastError(ex.getMessage());
                entity.setUpdatedAt(Instant.now(clock).toString());
                operations.saveAndFlush(entity);
            }));
        }
    }

    private void markFulfillRecovered(ReservationOperationEntity operation, String loanId) {
        transactionTemplate.executeWithoutResult(tx -> {
            ReservationEntity current = reservations.findById(operation.getReservationId()).orElseThrow();
            String nowIso = Instant.now(clock).toString();
            if (!"FULFILLED".equals(current.getStatus())) {
                current.setStatus("FULFILLED");
                current.setFulfilledAt(nowIso);
                current.setFulfilledLoanId(loanId);
                current.setFulfilledBy(operation.getActorId());
                current.setUpdatedAt(nowIso);
                current.setAggregateVersion(current.getAggregateVersion() + 1);
                reservations.saveAndFlush(current);
            }
            if (operation.getIdempotencyKey() != null && !operation.getIdempotencyKey().isBlank()
                    && operation.getRequestHash() != null && !operation.getRequestHash().isBlank()
                    && idempotencyRecords.findByActorIdAndOperationAndIdempotencyKey(
                            operation.getActorId(), "FULFILL_RESERVATION", operation.getIdempotencyKey()).isEmpty()) {
                try {
                    IdempotencyRecordEntity record = new IdempotencyRecordEntity();
                    record.setId(UUID.randomUUID().toString());
                    record.setActorId(operation.getActorId());
                    record.setOperation("FULFILL_RESERVATION");
                    record.setIdempotencyKey(operation.getIdempotencyKey());
                    record.setRequestHash(operation.getRequestHash());
                    record.setResponseStatus(200);
                    record.setResponseBody(mapper.writeValueAsString(ReservationResponse.from(current, 0)));
                    record.setCreatedAt(nowIso);
                    idempotencyRecords.saveAndFlush(record);
                } catch (JsonProcessingException ex) {
                    throw new IllegalStateException("Unable to persist recovered fulfillment replay", ex);
                }
            }
            operations.findById(operation.getId()).ifPresent(entity -> {
                entity.setStatus("COMPLETED");
                entity.setUpdatedAt(nowIso);
                entity.setLastError(null);
                operations.saveAndFlush(entity);
            });
        });
    }

    private record ExpiredReleaseTask(String reservationId, String copyId, String operationId) {
    }
}
