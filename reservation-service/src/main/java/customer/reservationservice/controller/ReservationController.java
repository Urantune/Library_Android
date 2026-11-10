package customer.reservationservice.controller;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import customer.reservationservice.client.CatalogInventoryClient;
import customer.reservationservice.client.CirculationLoanClient;
import customer.reservationservice.dto.ReservationDtos.ApiResponse;
import customer.reservationservice.dto.ReservationDtos.FulfilledLoanResult;
import customer.reservationservice.dto.ReservationDtos.PageResponse;
import customer.reservationservice.dto.ReservationDtos.ReservationResponse;
import customer.reservationservice.dto.request.ReservationRequest;
import customer.reservationservice.entity.IdempotencyRecordEntity;
import customer.reservationservice.entity.ReservationEntity;
import customer.reservationservice.entity.ReservationOperationEntity;
import customer.reservationservice.exception.ReservationException;
import customer.reservationservice.repository.IdempotencyRecordRepository;
import customer.reservationservice.repository.ReservationOperationRepository;
import customer.reservationservice.repository.ReservationEntityRepository;
import customer.reservationservice.security.ReservationJwtAuthResolver;
import customer.reservationservice.service.ReservationQueueService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Clock;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.transaction.annotation.Transactional;

@RestController
@RequestMapping("/api/reservations")
public class ReservationController {
    private static final String CREATE_OPERATION = "CREATE_RESERVATION";
    private static final String FULFILL_OPERATION = "FULFILL_RESERVATION";
    private static final List<String> ACTIVE_STATUSES = List.of("WAITING", "READY");

    private final ReservationJwtAuthResolver auth;
    private final ReservationEntityRepository reservations;
    private final ReservationOperationRepository operations;
    private final IdempotencyRecordRepository idempotencyRecords;
    private final CatalogInventoryClient catalog;
    private final CirculationLoanClient circulation;
    private final ObjectMapper mapper;
    private final Clock clock;

    public ReservationController(
            ReservationJwtAuthResolver auth,
            ReservationEntityRepository reservations,
            ReservationOperationRepository operations,
            IdempotencyRecordRepository idempotencyRecords,
            CatalogInventoryClient catalog,
            CirculationLoanClient circulation,
            ObjectMapper mapper,
            Clock clock
    ) {
        this.auth = auth;
        this.reservations = reservations;
        this.operations = operations;
        this.idempotencyRecords = idempotencyRecords;
        this.catalog = catalog;
        this.circulation = circulation;
        this.mapper = mapper;
        this.clock = clock;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ReservationResponse>> create(
            @Valid @RequestBody ReservationRequest request,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            HttpServletRequest servletRequest
    ) {
        var principal = auth.requireAuthenticated(servletRequest);
        String bookId = request.bookId().trim();
        String traceId = resolveTraceId(servletRequest);
        String requestHash = hash(bookId);

        if (idempotencyKey != null && !idempotencyKey.isBlank()) {
            var previous = idempotencyRecords.findByActorIdAndOperationAndIdempotencyKey(
                    principal.userId(), CREATE_OPERATION, idempotencyKey.trim());
            if (previous.isPresent()) {
                IdempotencyRecordEntity record = previous.get();
                if (!record.getRequestHash().equals(requestHash)) {
                    throw conflict("IDEMPOTENCY_KEY_CONFLICT", "Idempotency-Key was used with a different request");
                }
                return ResponseEntity.status(record.getResponseStatus()).body(readCached(record.getResponseBody()));
            }
        }

        if (catalog.getAvailability(bookId, traceId).availableCopies() > 0) {
            throw conflict("BOOK_COPIES_AVAILABLE", "A reservation is only allowed when no copies are available");
        }
        if (reservations.existsByUserIdAndBookIdAndStatusIn(principal.userId(), bookId, ACTIVE_STATUSES)) {
            throw conflict("DUPLICATE_ACTIVE_RESERVATION", "An active reservation already exists for this book");
        }

        String now = Instant.now(clock).toString();
        int queueNo = reservations.findFirstByBookIdOrderByQueueNoDesc(bookId)
                .map(existing -> existing.getQueueNo() + 1)
                .orElse(1);
        ReservationEntity reservation = new ReservationEntity();
        reservation.setId(UUID.randomUUID().toString());
        reservation.setUserId(principal.userId());
        reservation.setBookId(bookId);
        reservation.setStatus("WAITING");
        reservation.setQueueNo(queueNo);
        reservation.setCreatedAt(now);
        reservation.setUpdatedAt(now);

        try {
            ReservationEntity saved = reservations.saveAndFlush(reservation);
            ReservationResponse data = ReservationResponse.from(saved, queueNo);
            ApiResponse<ReservationResponse> body = ApiResponse.created(data, traceId);
            if (idempotencyKey != null && !idempotencyKey.isBlank()) {
                saveIdempotency(principal.userId(), CREATE_OPERATION, idempotencyKey.trim(), requestHash, 201, body);
            }
            return ResponseEntity.status(HttpStatus.CREATED).body(body);
        } catch (DataIntegrityViolationException ex) {
            throw conflict("DUPLICATE_ACTIVE_RESERVATION", "An active reservation already exists for this book");
        }
    }

    @GetMapping("/me")
    @Transactional(readOnly = true)
    public ApiResponse<PageResponse<ReservationResponse>> mine(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            HttpServletRequest servletRequest
    ) {
        var principal = auth.requireAuthenticated(servletRequest);
        if (page < 0 || size < 1 || size > 100) {
            throw new ReservationException(HttpStatus.BAD_REQUEST, "INVALID_PAGINATION", "page must be >= 0 and size must be between 1 and 100");
        }
        List<ReservationEntity> all = reservations.findByUserIdOrderByCreatedAtDesc(principal.userId());
        int start = Math.min(page * size, all.size());
        int end = Math.min(start + size, all.size());
        List<ReservationResponse> items = all.subList(start, end).stream()
                .map(entity -> ReservationResponse.from(entity, queuePosition(entity)))
                .toList();
        int totalPages = (int) Math.ceil((double) all.size() / size);
        return ApiResponse.ok(new PageResponse<>(items, page, size, all.size(), totalPages), resolveTraceId(servletRequest));
    }

    @PostMapping("/{id}/fulfill")
    public ApiResponse<ReservationResponse> fulfill(
            @PathVariable String id,
            @RequestHeader(value = "Idempotency-Key", required = false) String requestedKey,
            HttpServletRequest servletRequest
    ) {
        var principal = auth.requireStaff(servletRequest);
        String key = requestedKey == null || requestedKey.isBlank() ? UUID.randomUUID().toString() : requestedKey.trim();
        String requestHash = hash(id);
        var cached = idempotencyRecords.findByActorIdAndOperationAndIdempotencyKey(principal.userId(), FULFILL_OPERATION, key);
        if (cached.isPresent()) {
            if (!cached.get().getRequestHash().equals(requestHash)) {
                throw conflict("IDEMPOTENCY_KEY_CONFLICT", "Idempotency-Key was used with a different request");
            }
            return readCached(cached.get().getResponseBody());
        }

        ReservationEntity reservation = reservations.findById(id)
                .orElseThrow(() -> new ReservationException(HttpStatus.NOT_FOUND, "RESERVATION_NOT_FOUND", "Reservation not found"));
        if (!"READY".equals(reservation.getStatus()) || reservation.getHeldCopyId() == null) {
            throw conflict("RESERVATION_NOT_READY", "Reservation does not have a copy ready for pickup");
        }

        String now = Instant.now(clock).toString();
        String targetLoanId = UUID.randomUUID().toString();
        String operationId = UUID.randomUUID().toString();
        ReservationOperationEntity operation = new ReservationOperationEntity();
        operation.setId(operationId);
        operation.setReservationId(reservation.getId());
        operation.setOperationType("FULFILL");
        operation.setStatus("PENDING");
        operation.setBookId(reservation.getBookId());
        operation.setCopyId(reservation.getHeldCopyId());
        operation.setTargetLoanId(targetLoanId);
        operation.setActorId(principal.userId());
        operation.setIdempotencyKey(key);
        operation.setRequestHash(requestHash);
        operation.setAttemptCount(1);
        operation.setCreatedAt(now);
        operation.setUpdatedAt(now);
        operations.saveAndFlush(operation);

        String traceId = resolveTraceId(servletRequest);
        catalog.transferCopyHolder(reservation.getHeldCopyId(), reservation.getId(), "LOAN", targetLoanId,
                ReservationQueueService.deterministicUuid("transfer:" + operationId), traceId);
        FulfilledLoanResult loan;
        try {
            loan = circulation.fulfillReservationIntoLoan(targetLoanId, reservation.getId(), reservation.getUserId(),
                    reservation.getBookId(), reservation.getHeldCopyId(), principal.userId(),
                    ReservationQueueService.deterministicUuid("loan-commit:" + operationId), key, traceId);
        } catch (RuntimeException ex) {
            try {
                catalog.transferCopyHolder(reservation.getHeldCopyId(), targetLoanId, "RESERVATION", reservation.getId(),
                        ReservationQueueService.deterministicUuid("reverse-transfer:" + operationId), traceId);
                operation.setStatus("ABORTED");
                operation.setLastError(ex.getMessage());
            } catch (RuntimeException compensationError) {
                operation.setStatus("COMPENSATION_REQUIRED");
                operation.setNextRetryAt(Instant.now(clock).toString());
                operation.setLastError(String.valueOf(ex.getMessage()) + " | compensation error: " + compensationError.getMessage());
            }
            operation.setUpdatedAt(Instant.now(clock).toString());
            operations.saveAndFlush(operation);
            throw ex;
        }

        String fulfilledAt = Instant.now(clock).toString();
        reservation.setStatus("FULFILLED");
        reservation.setFulfilledAt(fulfilledAt);
        reservation.setFulfilledLoanId(loan.loanId());
        reservation.setFulfilledBy(principal.userId());
        reservation.setUpdatedAt(fulfilledAt);
        reservation.setAggregateVersion(reservation.getAggregateVersion() + 1);
        reservations.saveAndFlush(reservation);

        operation.setStatus("COMPLETED");
        operation.setUpdatedAt(fulfilledAt);
        operations.saveAndFlush(operation);

        ReservationResponse data = ReservationResponse.from(reservation, 0);
        ApiResponse<ReservationResponse> body = ApiResponse.ok(data, traceId);
        saveIdempotency(principal.userId(), FULFILL_OPERATION, key, requestHash, 200, body);
        return body;
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> cancel(@PathVariable String id, HttpServletRequest servletRequest) {
        var principal = auth.requireAuthenticated(servletRequest);
        ReservationEntity reservation = reservations.findById(id)
                .filter(entity -> entity.getUserId().equals(principal.userId()))
                .orElseThrow(() -> new ReservationException(HttpStatus.NOT_FOUND, "RESERVATION_NOT_FOUND", "Reservation not found"));
        if (!ACTIVE_STATUSES.contains(reservation.getStatus())) {
            throw conflict("RESERVATION_NOT_CANCELLABLE", "Reservation is not active");
        }
        String now = Instant.now(clock).toString();
        if ("READY".equals(reservation.getStatus()) && reservation.getHeldCopyId() != null) {
            catalog.releaseCopy(reservation.getHeldCopyId(), reservation.getId(), UUID.randomUUID().toString(),
                    "RESERVATION_CANCELLED", resolveTraceId(servletRequest));
        }
        reservation.setStatus("CANCELLED");
        reservation.setCancelledAt(now);
        reservation.setUpdatedAt(now);
        reservation.setAggregateVersion(reservation.getAggregateVersion() + 1);
        reservations.saveAndFlush(reservation);
        return ResponseEntity.noContent().build();
    }

    private int queuePosition(ReservationEntity entity) {
        if (!"WAITING".equals(entity.getStatus())) return 0;
        return reservations.findByBookIdAndStatusOrderByQueueNoAscCreatedAtAscIdAsc(entity.getBookId(), "WAITING")
                .stream().takeWhile(waiter -> !waiter.getId().equals(entity.getId())).toList().size() + 1;
    }

    private void saveIdempotency(String actorId, String operation, String key, String requestHash,
                                 int status, ApiResponse<ReservationResponse> response) {
        try {
            IdempotencyRecordEntity entity = new IdempotencyRecordEntity();
            entity.setId(UUID.randomUUID().toString());
            entity.setActorId(actorId);
            entity.setOperation(operation);
            entity.setIdempotencyKey(key);
            entity.setRequestHash(requestHash);
            entity.setResponseStatus(status);
            entity.setResponseBody(mapper.writeValueAsString(response));
            entity.setCreatedAt(Instant.now(clock).toString());
            idempotencyRecords.saveAndFlush(entity);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Unable to serialize idempotent response", ex);
        }
    }

    private ApiResponse<ReservationResponse> readCached(String json) {
        try {
            return mapper.readValue(json, mapper.getTypeFactory().constructParametricType(
                    ApiResponse.class, ReservationResponse.class));
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Unable to read cached idempotent response", ex);
        }
    }

    private static String hash(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 is unavailable", ex);
        }
    }

    private static ReservationException conflict(String code, String message) {
        return new ReservationException(HttpStatus.CONFLICT, code, message);
    }

    public static String resolveTraceId(HttpServletRequest request) {
        String value = request.getHeader("X-Trace-Id");
        if (value == null || value.isBlank()) value = request.getHeader("X-Correlation-Id");
        return value != null && value.matches("[a-zA-Z0-9-]{1,64}") ? value : UUID.randomUUID().toString();
    }
}
