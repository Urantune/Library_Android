package customer.reservationservice.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import customer.reservationservice.client.CatalogInventoryClient;
import customer.reservationservice.client.CirculationLoanClient;
import customer.reservationservice.dto.ReservationDtos.BookAvailability;
import customer.reservationservice.dto.ReservationDtos.FulfilledLoanResult;
import customer.reservationservice.dto.ReservationDtos.PageResponse;
import customer.reservationservice.dto.ReservationDtos.ReservationQuery;
import customer.reservationservice.dto.ReservationDtos.ReservationResponse;
import customer.reservationservice.entity.IdempotencyRecordEntity;
import customer.reservationservice.entity.ReservationEntity;
import customer.reservationservice.entity.ReservationOperationEntity;
import customer.reservationservice.exception.ReservationException;
import customer.reservationservice.repository.IdempotencyRecordRepository;
import customer.reservationservice.repository.ReservationOperationRepository;
import customer.reservationservice.repository.ReservationRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

@Service
public class ReservationService {
    private static final Logger log = LoggerFactory.getLogger(ReservationService.class);
    private static final Set<String> ACTIVE_STATUSES = Set.of("WAITING", "READY");
    private static final Set<String> ALL_STATUSES = Set.of("WAITING", "READY", "FULFILLED", "CANCELLED", "EXPIRED");

    private static final String OP_CREATE = "CREATE_RESERVATION";
    private static final String OP_FULFILL = "FULFILL_RESERVATION";

    private final ReservationRepository reservations;
    private final IdempotencyRecordRepository idempotencyRecords;
    private final ReservationOperationRepository operations;
    private final CatalogInventoryClient catalogClient;
    private final CirculationLoanClient circulationClient;
    private final TransactionTemplate transactionTemplate;
    private final ObjectMapper mapper;
    private final Clock clock;

    public ReservationService(
            ReservationRepository reservations,
            IdempotencyRecordRepository idempotencyRecords,
            ReservationOperationRepository operations,
            CatalogInventoryClient catalogClient,
            CirculationLoanClient circulationClient,
            TransactionTemplate transactionTemplate,
            ObjectMapper mapper,
            Clock clock
    ) {
        this.reservations = reservations;
        this.idempotencyRecords = idempotencyRecords;
        this.operations = operations;
        this.catalogClient = catalogClient;
        this.circulationClient = circulationClient;
        this.transactionTemplate = transactionTemplate;
        this.mapper = mapper;
        this.clock = clock;
    }

    public ReservationResponse create(String userId, String bookId, String idempotencyKey) {
        return create(userId, bookId, idempotencyKey, UUID.randomUUID().toString());
    }

    public ReservationResponse create(String userId, String bookId, String idempotencyKey, String traceId) {
        if (bookId == null || bookId.isBlank()) {
            throw new ReservationException(
                    HttpStatus.BAD_REQUEST,
                    "INVALID_BOOK_ID",
                    "bookId is required",
                    Map.of("bookId", "bookId is required")
            );
        }
        String trimmedBookId = bookId.trim();
        String normalizedKey = normalizeKey(idempotencyKey);
        String payloadHash = sha256("bookId=" + trimmedBookId);

        // Step 1 (Short TX): Check Idempotency-Key replay/conflict before external HTTP call
        if (normalizedKey != null) {
            Optional<ReservationResponse> cached = checkIdempotency(userId, OP_CREATE, normalizedKey, payloadHash);
            if (cached.isPresent()) {
                return cached.get();
            }
        }

        // Step 2 (OUTSIDE SQLite TX): Check Catalog book existence & availableCopies == 0
        BookAvailability availability = catalogClient.getAvailability(trimmedBookId, traceId);
        if (availability.availableCopies() > 0) {
            throw new ReservationException(
                    HttpStatus.CONFLICT,
                    "BOOK_COPIES_AVAILABLE",
                    "Book currently has available copies; borrow directly instead of placing a reservation"
            );
        }

        // Step 3 (Short SQLite TX): Enforce single active queue entry & persist WAITING reservation
        try {
            return transactionTemplate.execute(status -> {
                if (normalizedKey != null) {
                    Optional<ReservationResponse> replay = checkIdempotency(userId, OP_CREATE, normalizedKey, payloadHash);
                    if (replay.isPresent()) {
                        return replay.get();
                    }
                }
                if (reservations.existsByUserIdAndBookIdAndStatusIn(userId, trimmedBookId, ACTIVE_STATUSES)) {
                    throw new ReservationException(
                            HttpStatus.CONFLICT,
                            "DUPLICATE_ACTIVE_RESERVATION",
                            "User already has an active reservation for this book"
                    );
                }

                int nextQueueNo = reservations.findMaxQueueNoByBookId(trimmedBookId) + 1;
                String nowIso = Instant.now(clock).toString();

                ReservationEntity entity = new ReservationEntity();
                entity.setId(UUID.randomUUID().toString());
                entity.setUserId(userId);
                entity.setBookId(trimmedBookId);
                entity.setStatus("WAITING");
                entity.setQueueNo(nextQueueNo);
                entity.setCreatedAt(nowIso);
                entity.setUpdatedAt(nowIso);
                entity.setAggregateVersion(1);
                ReservationEntity saved = reservations.saveAndFlush(entity);

                int position = reservations.computeWaitingQueuePosition(trimmedBookId, saved.getQueueNo());
                ReservationResponse response = ReservationResponse.from(saved, position);

                if (normalizedKey != null) {
                    saveIdempotency(userId, OP_CREATE, normalizedKey, payloadHash, 201, response, nowIso);
                }
                return response;
            });
        } catch (DataIntegrityViolationException ex) {
            throw new ReservationException(
                    HttpStatus.CONFLICT,
                    "DUPLICATE_ACTIVE_RESERVATION",
                    "User already has an active reservation for this book"
            );
        }
    }

    public PageResponse<ReservationResponse> listMine(String userId, ReservationQuery query) {
        if (query.page() < 0 || query.size() < 1 || query.size() > 100) {
            throw new ReservationException(
                    HttpStatus.BAD_REQUEST,
                    "INVALID_PAGINATION",
                    "Page must be >= 0 and size between 1 and 100"
            );
        }
        String normalizedStatus = null;
        if (query.status() != null && !query.status().isBlank()) {
            normalizedStatus = query.status().trim().toUpperCase(Locale.ROOT);
            if (!ALL_STATUSES.contains(normalizedStatus)) {
                throw new ReservationException(
                        HttpStatus.BAD_REQUEST,
                        "INVALID_STATUS",
                        "Invalid reservation status filter: " + query.status(),
                        Map.of("status", "Invalid reservation status")
                );
            }
        }

        final String statusFilter = normalizedStatus;
        return transactionTemplate.execute(tx -> {
            var pageable = PageRequest.of(
                    query.page(),
                    query.size(),
                    Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"))
            );
            Page<ReservationEntity> pageResult = statusFilter == null
                    ? reservations.findByUserId(userId, pageable)
                    : reservations.findByUserIdAndStatus(userId, statusFilter, pageable);

            List<ReservationResponse> items = pageResult.getContent().stream()
                    .map(entity -> ReservationResponse.from(entity, resolveQueuePosition(entity)))
                    .toList();

            return new PageResponse<>(
                    items,
                    query.page(),
                    query.size(),
                    pageResult.getTotalElements(),
                    pageResult.getTotalPages()
            );
        });
    }

    public void cancel(String id, String userId) {
        cancel(id, userId, UUID.randomUUID().toString());
    }

    public void cancel(String id, String userId, String traceId) {
        if (id == null || id.isBlank()) {
            throw notFound();
        }

        // Step 1 (Short SQLite TX): Validate ownership & transition WAITING/READY -> CANCELLED
        CancelDecision decision = transactionTemplate.execute(tx -> {
            ReservationEntity entity = reservations.findById(id).orElseThrow(this::notFound);
            if (!entity.getUserId().equals(userId)) {
                throw notFound(); // Owner-only: hide other users' reservations with 404
            }
            if ("CANCELLED".equals(entity.getStatus())) {
                return CancelDecision.alreadyCancelled();
            }
            if (!"WAITING".equals(entity.getStatus()) && !"READY".equals(entity.getStatus())) {
                throw new ReservationException(
                        HttpStatus.CONFLICT,
                        "INVALID_RESERVATION_STATE",
                        "Cannot cancel reservation in status " + entity.getStatus()
                );
            }

            String nowIso = Instant.now(clock).toString();
            String heldCopy = "READY".equals(entity.getStatus()) ? entity.getHeldCopyId() : null;
            entity.setStatus("CANCELLED");
            entity.setCancelledAt(nowIso);
            entity.setUpdatedAt(nowIso);
            entity.setAggregateVersion(entity.getAggregateVersion() + 1);
            reservations.saveAndFlush(entity);

            if (heldCopy != null && !heldCopy.isBlank()) {
                String releaseOpId = ReservationQueueService.deterministicUuid("cancel-release:" + entity.getId());
                ReservationOperationEntity op = new ReservationOperationEntity();
                op.setId(releaseOpId);
                op.setReservationId(entity.getId());
                op.setOperationType("RELEASE_CANCEL");
                op.setStatus("PENDING");
                op.setBookId(entity.getBookId());
                op.setCopyId(heldCopy);
                op.setActorId(userId);
                op.setAttemptCount(1);
                op.setCreatedAt(nowIso);
                op.setUpdatedAt(nowIso);
                operations.saveAndFlush(op);
                return CancelDecision.releaseHeldCopy(entity.getId(), heldCopy, releaseOpId);
            }
            return CancelDecision.cancelledWithoutHold();
        });

        // Step 2 (OUTSIDE SQLite TX): Release held copy in Catalog so Catalog can emit CopyAvailable
        if (decision != null && decision.heldCopyId() != null) {
            try {
                catalogClient.releaseCopy(
                        decision.heldCopyId(),
                        decision.reservationId(),
                        decision.operationId(),
                        "RESERVATION_CANCELLED",
                        traceId
                );
                transactionTemplate.executeWithoutResult(tx -> operations.findById(decision.operationId()).ifPresent(op -> {
                    op.setStatus("COMPLETED");
                    op.setUpdatedAt(Instant.now(clock).toString());
                    operations.saveAndFlush(op);
                }));
            } catch (RuntimeException ex) {
                log.warn("Catalog release failed during cancel for reservation={}; marking COMPENSATION_REQUIRED for reconciler",
                        decision.reservationId(), ex);
                transactionTemplate.executeWithoutResult(tx -> operations.findById(decision.operationId()).ifPresent(op -> {
                    String nowIso = Instant.now(clock).toString();
                    op.setStatus("COMPENSATION_REQUIRED");
                    op.setNextRetryAt(nowIso);
                    op.setLastError(ex.getMessage());
                    op.setUpdatedAt(nowIso);
                    operations.saveAndFlush(op);
                }));
            }
        }
    }

    public ReservationResponse fulfill(String reservationId, String actor, String idempotencyKey) {
        return fulfill(reservationId, actor, idempotencyKey, UUID.randomUUID().toString());
    }

    public ReservationResponse fulfill(
            String reservationId,
            String actor,
            String idempotencyKey,
            String traceId
    ) {
        if (reservationId == null || reservationId.isBlank()) {
            throw notFound();
        }
        String normalizedKey = normalizeKey(idempotencyKey);
        String payloadHash = sha256("reservationId=" + reservationId.trim());

        if (normalizedKey != null) {
            Optional<ReservationResponse> cached = checkIdempotency(actor, OP_FULFILL, normalizedKey, payloadHash);
            if (cached.isPresent()) {
                return cached.get();
            }
        }

        // Step 1 (Short SQLite TX): Validate READY & non-expired, prepare FULFILL operation record
        FulfillContext ctx = transactionTemplate.execute(tx -> {
            ReservationEntity entity = reservations.findById(reservationId.trim()).orElseThrow(this::notFound);
            if (!"READY".equals(entity.getStatus())) {
                throw new ReservationException(
                        HttpStatus.CONFLICT,
                        "INVALID_RESERVATION_STATE",
                        "Only READY reservations can be fulfilled (current: " + entity.getStatus() + ")"
                );
            }
            if (entity.getHeldCopyId() == null || entity.getHeldCopyId().isBlank()) {
                throw new ReservationException(
                        HttpStatus.CONFLICT,
                        "MISSING_HELD_COPY",
                        "READY reservation has no held copy assigned"
                );
            }
            Instant now = Instant.now(clock);
            if (entity.getExpiresAt() != null && !Instant.parse(entity.getExpiresAt()).isAfter(now)) {
                throw new ReservationException(
                        HttpStatus.CONFLICT,
                        "RESERVATION_EXPIRED",
                        "Reservation hold window has already expired"
                );
            }

            String fulfillOpId = ReservationQueueService.deterministicUuid("fulfill:" + entity.getId());
            String targetLoanId = ReservationQueueService.deterministicUuid("loan-from-res:" + entity.getId());
            String nowIso = now.toString();

            ReservationOperationEntity op = operations.findById(fulfillOpId).orElseGet(() -> {
                ReservationOperationEntity created = new ReservationOperationEntity();
                created.setId(fulfillOpId);
                created.setReservationId(entity.getId());
                created.setOperationType("FULFILL");
                created.setBookId(entity.getBookId());
                created.setCopyId(entity.getHeldCopyId());
                created.setTargetLoanId(targetLoanId);
                created.setCreatedAt(nowIso);
                return created;
            });
            op.setActorId(actor);
            op.setIdempotencyKey(normalizedKey == null ? loanOpIdFor(fulfillOpId) : normalizedKey);
            op.setRequestHash(payloadHash);
            op.setStatus("PENDING");
            op.setAttemptCount(op.getAttemptCount() + 1);
            op.setUpdatedAt(nowIso);
            operations.saveAndFlush(op);

            return new FulfillContext(
                    entity.getId(),
                    entity.getUserId(),
                    entity.getBookId(),
                    entity.getHeldCopyId(),
                    op.getTargetLoanId(),
                    op.getId()
            );
        });

        String transferOpId = ReservationQueueService.deterministicUuid("transfer:" + ctx.operationId());
        String loanOpId = ReservationQueueService.deterministicUuid("loan-commit:" + ctx.operationId());

        // Step 2 (OUTSIDE SQLite TX): Transfer physical copy holder in Catalog from reservation -> targetLoanId
        try {
            catalogClient.transferCopyHolder(
                    ctx.copyId(),
                    ctx.reservationId(),
                    "LOAN",
                    ctx.targetLoanId(),
                    transferOpId,
                    traceId
            );
        } catch (RuntimeException transferEx) {
            markFulfillRecoveryPending(ctx.operationId(), transferEx.getMessage());
            throw transferEx;
        }

        transactionTemplate.executeWithoutResult(tx -> operations.findById(ctx.operationId()).ifPresent(op -> {
            op.setStatus("HOLDER_TRANSFERRED");
            op.setUpdatedAt(Instant.now(clock).toString());
            operations.saveAndFlush(op);
        }));

        // Step 3 (OUTSIDE SQLite TX): Commit loan in Circulation idempotently.
        // CRITICAL RULE: Only mark FULFILLED if Circulation confirms loan committed!
        FulfilledLoanResult committedLoan;
        try {
            committedLoan = circulationClient.fulfillReservationIntoLoan(
                    ctx.targetLoanId(),
                    ctx.reservationId(),
                    ctx.userId(),
                    ctx.bookId(),
                    ctx.copyId(),
                    actor,
                    loanOpId,
                    normalizedKey != null ? normalizedKey : loanOpId,
                    traceId
            );
        } catch (RuntimeException loanEx) {
            // The copy has already moved to the loan. If Circulation did not
            // confirm the commit, restore the reservation holder and retry later.
            compensateFailedFulfillTransfer(ctx, loanEx.getMessage(), traceId);
            throw loanEx;
        }

        // Step 4 (Short SQLite TX): Mark reservation FULFILLED + store Idempotency-Key response
        return transactionTemplate.execute(tx -> {
            ReservationEntity entity = reservations.findById(ctx.reservationId()).orElseThrow(this::notFound);
            String nowIso = Instant.now(clock).toString();
            entity.setStatus("FULFILLED");
            entity.setFulfilledAt(nowIso);
            entity.setFulfilledLoanId(committedLoan.loanId());
            entity.setFulfilledBy(actor);
            entity.setUpdatedAt(nowIso);
            entity.setAggregateVersion(entity.getAggregateVersion() + 1);
            ReservationEntity saved = reservations.saveAndFlush(entity);

            operations.findById(ctx.operationId()).ifPresent(op -> {
                op.setStatus("COMPLETED");
                op.setUpdatedAt(nowIso);
                operations.saveAndFlush(op);
            });

            ReservationResponse response = ReservationResponse.from(saved, 0);
            if (normalizedKey != null) {
                saveIdempotency(actor, OP_FULFILL, normalizedKey, payloadHash, 200, response, nowIso);
            }
            return response;
        });
    }

    private void compensateFailedFulfillTransfer(FulfillContext ctx, String errorReason, String traceId) {
        String compOpId = ReservationQueueService.deterministicUuid(
                "comp-transfer:" + ctx.operationId() + ":" + UUID.randomUUID()
        );
        try {
            catalogClient.transferCopyHolder(
                    ctx.copyId(),
                    ctx.targetLoanId(),
                    "RESERVATION",
                    ctx.reservationId(),
                    compOpId,
                    traceId
            );
            transactionTemplate.executeWithoutResult(tx -> operations.findById(ctx.operationId()).ifPresent(op -> {
                op.setStatus("COMPENSATED");
                op.setLastError(errorReason);
                op.setUpdatedAt(Instant.now(clock).toString());
                operations.saveAndFlush(op);
            }));
        } catch (RuntimeException compEx) {
            log.error("Failed immediate reverse holder transfer for reservation={}; scheduling reconciler recovery",
                    ctx.reservationId(), compEx);
            transactionTemplate.executeWithoutResult(tx -> operations.findById(ctx.operationId()).ifPresent(op -> {
                String nowIso = Instant.now(clock).toString();
                op.setStatus("COMPENSATION_REQUIRED");
                op.setNextRetryAt(nowIso);
                op.setLastError(errorReason + " | compensation error: " + compEx.getMessage());
                op.setUpdatedAt(nowIso);
                operations.saveAndFlush(op);
            }));
        }
    }

    private void markFulfillRecoveryPending(String operationId, String errorReason) {
        transactionTemplate.executeWithoutResult(tx -> operations.findById(operationId).ifPresent(op -> {
            String nowIso = Instant.now(clock).toString();
            op.setStatus("COMPENSATION_REQUIRED");
            op.setNextRetryAt(nowIso);
            op.setLastError(errorReason);
            op.setUpdatedAt(nowIso);
            operations.saveAndFlush(op);
        }));
    }

    private static String loanOpIdFor(String fulfillOperationId) {
        return ReservationQueueService.deterministicUuid("loan-commit:" + fulfillOperationId);
    }

    private int resolveQueuePosition(ReservationEntity entity) {
        if (!"WAITING".equals(entity.getStatus())) {
            return 0;
        }
        return reservations.computeWaitingQueuePosition(entity.getBookId(), entity.getQueueNo());
    }

    private Optional<ReservationResponse> checkIdempotency(
            String actorId,
            String operation,
            String key,
            String payloadHash
    ) {
        return transactionTemplate.execute(tx -> idempotencyRecords
                .findByActorIdAndOperationAndIdempotencyKey(actorId, operation, key)
                .map(existing -> {
                    if (!existing.getRequestHash().equals(payloadHash)) {
                        throw new ReservationException(
                                HttpStatus.CONFLICT,
                                "IDEMPOTENCY_KEY_CONFLICT",
                                "Idempotency-Key was already used with a different request payload"
                        );
                    }
                    try {
                        return mapper.readValue(existing.getResponseBody(), ReservationResponse.class);
                    } catch (JsonProcessingException ex) {
                        throw new IllegalStateException("Corrupt stored idempotency response", ex);
                    }
                }));
    }

    private void saveIdempotency(
            String actorId,
            String operation,
            String key,
            String payloadHash,
            int responseStatus,
            ReservationResponse response,
            String nowIso
    ) {
        try {
            IdempotencyRecordEntity record = new IdempotencyRecordEntity();
            record.setId(UUID.randomUUID().toString());
            record.setActorId(actorId);
            record.setOperation(operation);
            record.setIdempotencyKey(key);
            record.setRequestHash(payloadHash);
            record.setResponseStatus(responseStatus);
            record.setResponseBody(mapper.writeValueAsString(response));
            record.setCreatedAt(nowIso);
            idempotencyRecords.saveAndFlush(record);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Failed to serialize idempotency response", ex);
        }
    }

    private static String normalizeKey(String key) {
        return (key == null || key.isBlank()) ? null : key.trim();
    }

    private static String sha256(String input) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(input.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (Exception ex) {
            throw new IllegalStateException("SHA-256 unavailable", ex);
        }
    }

    private ReservationException notFound() {
        return new ReservationException(HttpStatus.NOT_FOUND, "RESERVATION_NOT_FOUND", "Reservation not found");
    }

    private record CancelDecision(String reservationId, String heldCopyId, String operationId) {
        static CancelDecision alreadyCancelled() { return new CancelDecision(null, null, null); }
        static CancelDecision cancelledWithoutHold() { return new CancelDecision(null, null, null); }
        static CancelDecision releaseHeldCopy(String reservationId, String heldCopyId, String operationId) {
            return new CancelDecision(reservationId, heldCopyId, operationId);
        }
    }

    private record FulfillContext(
            String reservationId,
            String userId,
            String bookId,
            String copyId,
            String targetLoanId,
            String operationId
    ) {
    }
}
