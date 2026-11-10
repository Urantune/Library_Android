package catalogservice.service;

import catalogservice.dto.response.CopyAvailableEvent;
import catalogservice.dto.response.LoanReturnedEvent;
import catalogservice.entity.BookCopy;
import catalogservice.entity.CatalogOutboxEvent;
import catalogservice.entity.CopyOperation;
import catalogservice.entity.ProcessedCatalogEvent;
import catalogservice.entity.ProcessedCatalogEventId;
import catalogservice.enums.BookConditionStatus;
import catalogservice.enums.BookCopyStatus;
import catalogservice.repository.BookCopyRepository;
import catalogservice.repository.CatalogOutboxRepository;
import catalogservice.repository.CopyOperationRepository;
import catalogservice.repository.ProcessedCatalogEventRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Clock;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class CopyInventoryService {
    public static final String TOPIC_COPY_AVAILABLE = "library.copy.available.v1";
    public static final String GROUP_LOAN_RETURNED = "catalog-loan-returned-v1";

    private static final Set<BookCopyStatus> HELD_STATUSES = Set.of(BookCopyStatus.RESERVED, BookCopyStatus.BORROWED);
    private static final Set<String> VALID_HOLDERS = Set.of("RESERVATION", "LOAN");

    private final BookCopyRepository copies;
    private final CopyOperationRepository operations;
    private final CatalogOutboxRepository outbox;
    private final ProcessedCatalogEventRepository processedEvents;
    private final ObjectMapper mapper;
    private final Clock clock;
    private final PublisherCacheInvalidator cacheInvalidator;

    public CopyInventoryService(
            BookCopyRepository copies,
            CopyOperationRepository operations,
            CatalogOutboxRepository outbox,
            ProcessedCatalogEventRepository processedEvents,
            ObjectMapper mapper,
            Clock clock,
            PublisherCacheInvalidator cacheInvalidator
    ) {
        this.copies = copies;
        this.operations = operations;
        this.outbox = outbox;
        this.processedEvents = processedEvents;
        this.mapper = mapper;
        this.clock = clock;
        this.cacheInvalidator = cacheInvalidator;
    }

    @Transactional
    public void claim(String bookId, String copyId, String holderType, String holderId, String operationId) {
        String holder = normalizeHolder(holderType);
        String normalizedBookId = required(bookId, "bookId");
        String normalizedHolderId = required(holderId, "holderId");
        String opId = required(operationId, "operationId");
        String fingerprint = hash("CLAIM\n" + normalizedBookId + "\n" + copyId + "\n" + holder
                + "\n" + normalizedHolderId);
        if (replay(opId, fingerprint)) return;

        BookCopy copy = requireCopy(copyId);
        if (copy.getBook() == null || !normalizedBookId.equals(copy.getBook().getId())) {
            throw conflict("Copy does not belong to the requested book");
        }
        BookCopyStatus target = statusForHolder(holder);
        if (copies.transitionFromStatus(copyId, BookCopyStatus.AVAILABLE, target, holder, normalizedHolderId) != 1) {
            throw conflict("Copy is not available for claim");
        }
        operations.saveAndFlush(new CopyOperation(opId, fingerprint, "CLAIM", now()));
        cacheInvalidator.evictBookCachesAfterCommit();
    }

    @Transactional
    public void release(String copyId, String expectedHolderId, String operationId, String reason, String traceId) {
        String expected = required(expectedHolderId, "expectedHolderId");
        String opId = required(operationId, "operationId");
        String normalizedReason = required(reason, "reason");
        String fingerprint = hash("RELEASE\n" + copyId + "\n" + expected + "\n" + normalizedReason);
        if (replay(opId, fingerprint)) return;

        BookCopy copy = requireCopy(copyId);
        BookCopyStatus releasedStatus = availableStatus(copy.getConditionStatus());
        String bookId = copy.getBook().getId();
        long nextVersion = copy.getAggregateVersion() + 1;
        if (copies.transitionFromHolder(copyId, expected, HELD_STATUSES, releasedStatus, null, null) != 1) {
            throw conflict("Copy holder does not match expectedHolderId");
        }
        operations.saveAndFlush(new CopyOperation(opId, fingerprint, "RELEASE", now()));
        if (releasedStatus == BookCopyStatus.AVAILABLE) {
            enqueueCopyAvailable(bookId, copyId, normalizedReason, traceId, nextVersion);
        }
        cacheInvalidator.evictBookCachesAfterCommit();
    }

    @Transactional
    public void transfer(
            String copyId,
            String expectedHolderId,
            String newHolderType,
            String newHolderId,
            String operationId
    ) {
        String expected = required(expectedHolderId, "expectedHolderId");
        String holder = normalizeHolder(newHolderType);
        String normalizedNewHolder = required(newHolderId, "newHolderId");
        String opId = required(operationId, "operationId");
        String fingerprint = hash("TRANSFER\n" + copyId + "\n" + expected + "\n" + holder + "\n" + normalizedNewHolder);
        if (replay(opId, fingerprint)) return;

        requireCopy(copyId);
        if (copies.transitionFromHolder(copyId, expected, HELD_STATUSES, statusForHolder(holder), holder,
                normalizedNewHolder) != 1) {
            throw conflict("Copy holder does not match expectedHolderId");
        }
        operations.saveAndFlush(new CopyOperation(opId, fingerprint, "TRANSFER", now()));
        cacheInvalidator.evictBookCachesAfterCommit();
    }

    @Transactional
    public void onLoanReturned(LoanReturnedEvent event) {
        if (event == null || event.eventId() == null || event.eventId().isBlank()
                || event.schemaVersion() != 1
                || !"library.loan.returned.v1".equals(event.type()) || event.payload() == null) {
            throw new IllegalArgumentException("Invalid loan-returned event envelope");
        }
        ProcessedCatalogEventId dedupId = new ProcessedCatalogEventId(GROUP_LOAN_RETURNED, event.eventId().trim());
        if (processedEvents.existsById(dedupId)) return;

        String copyId = payloadString(event.payload(), "copyId");
        String loanId = payloadString(event.payload(), "loanId");
        String eventBookId = payloadString(event.payload(), "bookId");
        if (!loanId.equals(event.aggregateId())) {
            throw new IllegalArgumentException("Loan-returned aggregateId does not match loanId");
        }
        String conditionValue = optionalString(event.payload().get("condition"));
        BookCopy copy = requireCopy(copyId);
        if (copy.getBook() == null || !eventBookId.equals(copy.getBook().getId())) {
            throw new IllegalArgumentException("Loan-returned bookId does not match the Catalog copy");
        }
        if (copy.getStatus() != BookCopyStatus.BORROWED || !loanId.equals(copy.getHolderId())) {
            throw conflict("Returned loan does not match the current copy holder");
        }

        if (conditionValue != null) {
            try {
                copy.setConditionStatus(BookConditionStatus.valueOf(conditionValue.toUpperCase(java.util.Locale.ROOT)));
            } catch (IllegalArgumentException ex) {
                throw new IllegalArgumentException("Unsupported returned copy condition", ex);
            }
        }
        BookCopyStatus nextStatus = availableStatus(copy.getConditionStatus());
        String bookId = copy.getBook().getId();
        long nextVersion = copy.getAggregateVersion() + 1;
        copy.setStatus(nextStatus);
        copy.setHolderType(null);
        copy.setHolderId(null);
        copy.setAggregateVersion(nextVersion);
        copies.saveAndFlush(copy);

        String now = now();
        processedEvents.saveAndFlush(new ProcessedCatalogEvent(dedupId, "library.loan.returned.v1", now));
        if (nextStatus == BookCopyStatus.AVAILABLE) {
            enqueueCopyAvailable(bookId, copyId, "LOAN_RETURNED", event.traceId(), nextVersion);
        }
        cacheInvalidator.evictBookCachesAfterCommit();
    }

    private void enqueueCopyAvailable(String bookId, String copyId, String reason, String traceId, long version) {
        String occurredAt = now();
        String eventTrace = traceId == null || !traceId.matches("[a-zA-Z0-9-]{1,64}")
                ? UUID.randomUUID().toString()
                : traceId;
        CopyAvailableEvent event = new CopyAvailableEvent(
                UUID.randomUUID().toString(),
                TOPIC_COPY_AVAILABLE,
                1,
                occurredAt,
                eventTrace,
                bookId,
                version,
                Map.of(
                        "bookId", bookId,
                        "copyId", copyId,
                        "availableAt", occurredAt,
                        "reason", normalizeReason(reason)
                )
        );
        try {
            outbox.saveAndFlush(new CatalogOutboxEvent(
                    event.eventId(), bookId, TOPIC_COPY_AVAILABLE, mapper.writeValueAsString(event), occurredAt));
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Could not serialize CopyAvailable event", ex);
        }
    }

    private boolean replay(String operationId, String fingerprint) {
        return operations.findById(operationId).map(existing -> {
            if (!existing.getRequestHash().equals(fingerprint)) {
                throw conflict("operationId was already used for a different copy operation");
            }
            return true;
        }).orElse(false);
    }

    private BookCopy requireCopy(String copyId) {
        String id = required(copyId, "copyId");
        return copies.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Copy not found"));
    }

    private static BookCopyStatus statusForHolder(String holderType) {
        return "RESERVATION".equals(holderType) ? BookCopyStatus.RESERVED : BookCopyStatus.BORROWED;
    }

    private static BookCopyStatus availableStatus(BookConditionStatus condition) {
        if (condition == BookConditionStatus.DAMAGED) return BookCopyStatus.DAMAGED;
        if (condition == BookConditionStatus.LOST) return BookCopyStatus.LOST;
        return BookCopyStatus.AVAILABLE;
    }

    private static String normalizeHolder(String value) {
        String holder = required(value, "holderType").toUpperCase(java.util.Locale.ROOT);
        if (!VALID_HOLDERS.contains(holder)) throw conflict("holderType must be RESERVATION or LOAN");
        return holder;
    }

    private static String normalizeReason(String reason) {
        if (!Set.of("LOAN_RETURNED", "RESERVATION_EXPIRED", "RESERVATION_CANCELLED", "COPY_ADDED").contains(reason)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unsupported copy-available reason");
        }
        return reason;
    }

    private static String payloadString(Map<String, Object> payload, String name) {
        Object value = payload.get(name);
        if (!(value instanceof String text) || text.isBlank()) {
            throw new IllegalArgumentException("Loan-returned event missing " + name);
        }
        return text.trim();
    }

    private static String optionalString(Object value) {
        return value instanceof String text && !text.isBlank() ? text.trim() : null;
    }

    private static String required(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, name + " is required");
        }
        return value.trim();
    }

    private String now() {
        return Instant.now(clock).toString();
    }

    private static String hash(String input) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(input.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 is unavailable", ex);
        }
    }

    private static ResponseStatusException conflict(String message) {
        return new ResponseStatusException(HttpStatus.CONFLICT, message);
    }
}
