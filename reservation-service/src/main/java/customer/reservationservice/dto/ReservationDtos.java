package customer.reservationservice.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import customer.reservationservice.entity.ReservationEntity;
import jakarta.validation.constraints.NotBlank;
import java.time.Instant;
import java.util.List;
import java.util.Map;

public final class ReservationDtos {
    private ReservationDtos() {
    }

    public record ApiResponse<T>(int status, String message, T data, Instant timestamp, String traceId) {
        public static <T> ApiResponse<T> ok(T data, String traceId) {
            return new ApiResponse<>(200, "OK", data, Instant.now(), traceId);
        }

        public static <T> ApiResponse<T> created(T data, String traceId) {
            return new ApiResponse<>(201, "Created", data, Instant.now(), traceId);
        }
    }

    public record PageResponse<T>(List<T> items, int page, int size, long totalElements, int totalPages) {
    }

    public record CreateReservationRequest(
            @NotBlank(message = "bookId is required")
            String bookId
    ) {
    }

    public record ReservationQuery(String status, int page, int size) {
    }

    public record ReservationResponse(
            String id,
            String userId,
            String bookId,
            String copyId,
            String status,
            int queuePosition,
            String readyAt,
            String expiresAt,
            String fulfilledAt,
            String cancelledAt,
            String fulfilledLoanId,
            String createdAt
    ) {
        public static ReservationResponse from(ReservationEntity entity, int queuePosition) {
            return new ReservationResponse(
                    entity.getId(),
                    entity.getUserId(),
                    entity.getBookId(),
                    entity.getHeldCopyId(),
                    entity.getStatus(),
                    queuePosition,
                    entity.getReadyAt(),
                    entity.getExpiresAt(),
                    entity.getFulfilledAt(),
                    entity.getCancelledAt(),
                    entity.getFulfilledLoanId(),
                    entity.getCreatedAt()
            );
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record KafkaEventEnvelope(
            String eventId,
            String type,
            Integer schemaVersion,
            String occurredAt,
            String traceId,
            String aggregateId,
            Integer aggregateVersion,
            Map<String, Object> payload
    ) {
    }

    public record BookAvailability(String bookId, int totalCopies, long availableCopies) {
    }

    public enum ClaimOutcome {
        CLAIMED,
        COPY_UNAVAILABLE
    }

    public record FulfilledLoanResult(String loanId, String status) {
    }
}
