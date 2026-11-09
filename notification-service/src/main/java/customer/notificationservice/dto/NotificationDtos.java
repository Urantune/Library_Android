package customer.notificationservice.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import customer.notificationservice.entity.DeviceTokenEntity;
import customer.notificationservice.entity.NotificationEntity;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.Map;

public final class NotificationDtos {
    private NotificationDtos() {
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

    public record NotificationQuery(Boolean unreadOnly, int page, int size) {
    }

    public record NotificationResponse(
            String id,
            String type,
            String title,
            String body,
            boolean isRead,
            String referenceType,
            String referenceId,
            String readAt,
            String createdAt
    ) {
        public static NotificationResponse from(NotificationEntity entity) {
            return new NotificationResponse(
                    entity.getId(),
                    entity.getType(),
                    entity.getTitle(),
                    entity.getBody(),
                    entity.getIsRead() == 1,
                    entity.getReferenceType(),
                    entity.getReferenceId(),
                    entity.getReadAt(),
                    entity.getCreatedAt()
            );
        }
    }

    public record UnreadCountResponse(long unreadCount) {
    }

    public record MarkAllReadResponse(int updatedCount) {
    }

    public record DeviceTokenRequest(
            @NotBlank(message = "FCM token is required")
            @Size(max = 2048, message = "FCM token is too long")
            String token,
            @NotBlank(message = "Platform is required")
            String platform
    ) {
    }

    public record DeviceTokenResponse(
            String id,
            String platform,
            boolean active,
            String createdAt,
            String updatedAt
    ) {
        public static DeviceTokenResponse from(DeviceTokenEntity entity) {
            return new DeviceTokenResponse(
                    entity.getId(),
                    entity.getPlatform(),
                    entity.getActive() == 1,
                    entity.getCreatedAt(),
                    entity.getUpdatedAt()
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

    public record ComposedNotification(
            String userId,
            String type,
            String title,
            String body,
            String referenceType,
            String referenceId
    ) {
    }
}
