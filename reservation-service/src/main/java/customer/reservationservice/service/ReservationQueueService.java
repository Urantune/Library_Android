package customer.reservationservice.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import customer.reservationservice.client.CatalogInventoryClient;
import customer.reservationservice.dto.ReservationDtos.ClaimOutcome;
import customer.reservationservice.dto.ReservationDtos.KafkaEventEnvelope;
import customer.reservationservice.dto.ReservationDtos.ReservationResponse;
import customer.reservationservice.entity.OutboxEventEntity;
import customer.reservationservice.entity.ProcessedEventEntity;
import customer.reservationservice.entity.ProcessedEventId;
import customer.reservationservice.entity.ReservationEntity;
import customer.reservationservice.entity.ReservationOperationEntity;
import customer.reservationservice.repository.OutboxEventRepository;
import customer.reservationservice.repository.ProcessedEventRepository;
import customer.reservationservice.repository.ReservationOperationRepository;
import customer.reservationservice.repository.ReservationEntityRepository;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

@Service
public class ReservationQueueService {
    private static final Logger log = LoggerFactory.getLogger(ReservationQueueService.class);
    public static final String TOPIC_RESERVATION_READY = "library.reservation.ready.v1";
    public static final String CONSUMER_GROUP_COPY_AVAILABLE = "reservation-copy-available-v1";

    private final ReservationEntityRepository reservations;
    private final OutboxEventRepository outboxEvents;
    private final ProcessedEventRepository processedEvents;
    private final ReservationOperationRepository operations;
    private final CatalogInventoryClient catalogClient;
    private final TransactionTemplate transactionTemplate;
    private final ObjectMapper mapper;
    private final Clock clock;
    private final long holdHours;

    private final ConcurrentHashMap<String, Object> copyLocks = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Object> bookLocks = new ConcurrentHashMap<>();

    public ReservationQueueService(
            ReservationEntityRepository reservations,
            OutboxEventRepository outboxEvents,
            ProcessedEventRepository processedEvents,
            ReservationOperationRepository operations,
            CatalogInventoryClient catalogClient,
            TransactionTemplate transactionTemplate,
            ObjectMapper mapper,
            Clock clock,
            @Value("${app.reservation.hold-hours:24}") long holdHours
    ) {
        this.reservations = reservations;
        this.outboxEvents = outboxEvents;
        this.processedEvents = processedEvents;
        this.operations = operations;
        this.catalogClient = catalogClient;
        this.transactionTemplate = transactionTemplate;
        this.mapper = mapper;
        this.clock = clock;
        this.holdHours = holdHours;
    }

    public Optional<ReservationResponse> assignNext(String bookId, String copyId) {
        return assignNext(bookId, copyId, null, UUID.randomUUID().toString());
    }

    public Optional<ReservationResponse> assignNext(
            String bookId,
            String copyId,
            String sourceEventId,
            String traceId
    ) {
        Object copyMonitor = copyLocks.computeIfAbsent(copyId, k -> new Object());
        synchronized (copyMonitor) {
            Object bookMonitor = bookLocks.computeIfAbsent(bookId, k -> new Object());
            synchronized (bookMonitor) {
                return doAssignNext(bookId, copyId, sourceEventId, traceId);
            }
        }
    }

    private Optional<ReservationResponse> doAssignNext(
            String bookId,
            String copyId,
            String sourceEventId,
            String traceId
    ) {
        String effectiveTrace = (traceId == null || traceId.isBlank()) ? UUID.randomUUID().toString() : traceId;

        // Step 1 (Short SQLite TX): Check dedup, check copy not already held READY, pick head of WAITING queue
        CandidateSelection selection = transactionTemplate.execute(status -> {
            if (sourceEventId != null && !sourceEventId.isBlank()) {
                ProcessedEventId dedupKey = new ProcessedEventId(CONSUMER_GROUP_COPY_AVAILABLE, sourceEventId);
                if (processedEvents.existsById(dedupKey)) {
                    return CandidateSelection.alreadyProcessed();
                }
            }
            if (reservations.existsByHeldCopyIdAndStatus(copyId, "READY")) {
                recordProcessedIfPresent(sourceEventId);
                return CandidateSelection.copyAlreadyHeld();
            }
            Optional<ReservationEntity> head = reservations
                    .findFirstByBookIdAndStatusOrderByQueueNoAscCreatedAtAscIdAsc(bookId, "WAITING");
            if (head.isEmpty()) {
                recordProcessedIfPresent(sourceEventId);
                return CandidateSelection.noWaiter();
            }

            ReservationEntity candidate = head.get();
            String nowIso = Instant.now(clock).toString();
            String claimOpId = deterministicUuid("claim:" + candidate.getId() + ":" + copyId);

            ReservationOperationEntity op = operations.findById(claimOpId).orElseGet(() -> {
                ReservationOperationEntity created = new ReservationOperationEntity();
                created.setId(claimOpId);
                created.setReservationId(candidate.getId());
                created.setOperationType("CLAIM_COPY");
                created.setBookId(bookId);
                created.setCopyId(copyId);
                created.setCreatedAt(nowIso);
                return created;
            });
            op.setStatus("PENDING");
            op.setAttemptCount(op.getAttemptCount() + 1);
            op.setUpdatedAt(nowIso);
            operations.saveAndFlush(op);

            return CandidateSelection.of(candidate.getId(), claimOpId);
        });

        if (selection == null || !selection.hasCandidate()) {
            return Optional.empty();
        }

        // Step 2 (OUTSIDE SQLite TX): Claim physical copy in Catalog
        ClaimOutcome claimOutcome = catalogClient.claimCopyForReservation(
                bookId,
                copyId,
                selection.reservationId(),
                selection.operationId(),
                effectiveTrace
        );

        if (claimOutcome == ClaimOutcome.COPY_UNAVAILABLE) {
            transactionTemplate.executeWithoutResult(status -> {
                operations.findById(selection.operationId()).ifPresent(op -> {
                    op.setStatus("ABORTED");
                    op.setLastError("Copy unavailable in Catalog");
                    op.setUpdatedAt(Instant.now(clock).toString());
                    operations.saveAndFlush(op);
                });
                recordProcessedIfPresent(sourceEventId);
            });
            return Optional.empty();
        }

        // Step 3 (Short SQLite TX): Commit READY + 24h expiresAt + Outbox + Dedup
        CommitOutcome commitOutcome;
        try {
            commitOutcome = transactionTemplate.execute(status -> {
                ReservationEntity current = reservations.findById(selection.reservationId()).orElse(null);
                String nowIso = Instant.now(clock).toString();

                if (current == null
                        || !"WAITING".equals(current.getStatus())
                        || reservations.existsByHeldCopyIdAndStatus(copyId, "READY")) {
                    operations.findById(selection.operationId()).ifPresent(op -> {
                        op.setStatus("COMPENSATION_REQUIRED");
                        op.setLastError("Reservation cancelled or copy claimed concurrently before READY commit");
                        op.setNextRetryAt(nowIso);
                        op.setUpdatedAt(nowIso);
                        operations.saveAndFlush(op);
                    });
                    return CommitOutcome.needsReleaseCompensation();
                }

                Instant readyInstant = Instant.now(clock);
                Instant expiresInstant = readyInstant.plus(Duration.ofHours(holdHours));
                String readyIso = readyInstant.toString();
                String expiresIso = expiresInstant.toString();

                current.setStatus("READY");
                current.setHeldCopyId(copyId);
                current.setReadyAt(readyIso);
                current.setExpiresAt(expiresIso);
                current.setUpdatedAt(readyIso);
                current.setAggregateVersion(current.getAggregateVersion() + 1);
                ReservationEntity saved = reservations.saveAndFlush(current);

                OutboxEventEntity outbox = buildReservationReadyOutbox(saved, copyId, readyIso, expiresIso, effectiveTrace);
                outboxEvents.saveAndFlush(outbox);

                operations.findById(selection.operationId()).ifPresent(op -> {
                    op.setStatus("COMPLETED");
                    op.setUpdatedAt(readyIso);
                    operations.saveAndFlush(op);
                });
                recordProcessedIfPresent(sourceEventId);

                return CommitOutcome.committed(ReservationResponse.from(saved, 0));
            });
        } catch (DataIntegrityViolationException integrityEx) {
            log.warn("Unique constraint prevented duplicate copy hold on copyId={}; triggering release compensation", copyId);
            compensateClaimedCopy(copyId, selection.reservationId(), selection.operationId(), effectiveTrace);
            return Optional.empty();
        }

        if (commitOutcome != null && commitOutcome.compensateRelease()) {
            compensateClaimedCopy(copyId, selection.reservationId(), selection.operationId(), effectiveTrace);
            return Optional.empty();
        }

        return commitOutcome == null ? Optional.empty() : Optional.ofNullable(commitOutcome.response());
    }

    private void compensateClaimedCopy(String copyId, String reservationId, String opId, String traceId) {
        String releaseOpId = deterministicUuid("comp-release:" + opId);
        try {
            catalogClient.releaseCopy(copyId, reservationId, releaseOpId, "RESERVATION_CANCELLED", traceId);
            transactionTemplate.executeWithoutResult(status -> operations.findById(opId).ifPresent(op -> {
                op.setStatus("COMPENSATED");
                op.setUpdatedAt(Instant.now(clock).toString());
                operations.saveAndFlush(op);
            }));
        } catch (RuntimeException ex) {
            log.warn("Failed immediate release compensation for copyId={}, scheduled reconciler will retry", copyId, ex);
        }
    }

    private OutboxEventEntity buildReservationReadyOutbox(
            ReservationEntity reservation,
            String copyId,
            String readyIso,
            String expiresIso,
            String traceId
    ) {
        String eventId = UUID.randomUUID().toString();
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("reservationId", reservation.getId());
        payload.put("userId", reservation.getUserId());
        payload.put("bookId", reservation.getBookId());
        payload.put("copyId", copyId);
        payload.put("readyAt", readyIso);
        payload.put("expiresAt", expiresIso);

        KafkaEventEnvelope envelope = new KafkaEventEnvelope(
                eventId,
                TOPIC_RESERVATION_READY,
                1,
                readyIso,
                traceId,
                reservation.getId(),
                reservation.getAggregateVersion(),
                payload
        );

        String serialized;
        try {
            serialized = mapper.writeValueAsString(envelope);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Failed to serialize reservation.ready outbox event", ex);
        }

        OutboxEventEntity outbox = new OutboxEventEntity();
        outbox.setId(eventId);
        outbox.setAggregateType("RESERVATION");
        outbox.setAggregateId(reservation.getId());
        outbox.setEventType(TOPIC_RESERVATION_READY);
        outbox.setTopic(TOPIC_RESERVATION_READY);
        outbox.setTraceId(traceId);
        outbox.setPayload(serialized);
        outbox.setStatus("PENDING");
        outbox.setRetryCount(0);
        outbox.setCreatedAt(readyIso);
        return outbox;
    }

    private void recordProcessedIfPresent(String sourceEventId) {
        if (sourceEventId != null && !sourceEventId.isBlank()) {
            ProcessedEventId key = new ProcessedEventId(CONSUMER_GROUP_COPY_AVAILABLE, sourceEventId.trim());
            if (!processedEvents.existsById(key)) {
                processedEvents.saveAndFlush(new ProcessedEventEntity(
                        key,
                        "library.copy.available.v1",
                        Instant.now(clock).toString()
                ));
            }
        }
    }

    public static String deterministicUuid(String seed) {
        return UUID.nameUUIDFromBytes(seed.getBytes(StandardCharsets.UTF_8)).toString();
    }

    private record CandidateSelection(String reservationId, String operationId) {
        static CandidateSelection of(String reservationId, String operationId) {
            return new CandidateSelection(reservationId, operationId);
        }

        static CandidateSelection alreadyProcessed() { return new CandidateSelection(null, null); }
        static CandidateSelection copyAlreadyHeld() { return new CandidateSelection(null, null); }
        static CandidateSelection noWaiter() { return new CandidateSelection(null, null); }

        boolean hasCandidate() { return reservationId != null; }
    }

    private record CommitOutcome(ReservationResponse response, boolean compensateRelease) {
        static CommitOutcome committed(ReservationResponse response) {
            return new CommitOutcome(response, false);
        }

        static CommitOutcome needsReleaseCompensation() {
            return new CommitOutcome(null, true);
        }
    }
}
