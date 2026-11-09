package customer.notificationservice.service;

import customer.notificationservice.dto.NotificationDtos.ComposedNotification;
import customer.notificationservice.dto.NotificationDtos.KafkaEventEnvelope;
import java.util.Map;
import org.springframework.stereotype.Component;

/**
 * Composes user-facing notification title/body/reference strictly from the Kafka event payload.
 * Never accesses another service's database.
 */
@Component
public class NotificationComposer {
    public static final String TOPIC_LOAN_APPROVED = "library.loan.approved.v1";
    public static final String TOPIC_LOAN_RETURNED = "library.loan.returned.v1";
    public static final String TOPIC_LOAN_OVERDUE = "library.loan.overdue.v1";
    public static final String TOPIC_RESERVATION_READY = "library.reservation.ready.v1";

    public ComposedNotification compose(KafkaEventEnvelope event) {
        if (event == null || event.type() == null || event.payload() == null) {
            throw new IllegalArgumentException("Event envelope, type, and payload are required");
        }
        Map<String, Object> payload = event.payload();
        String userId = requireString(payload, "userId");

        return switch (event.type()) {
            case TOPIC_LOAN_APPROVED -> {
                String loanId = requireString(payload, "loanId");
                String copyId = requireString(payload, "copyId");
                String dueInfo = optionalString(payload, "dueAt");
                String pickupBy = optionalString(payload, "pickupBy");
                String suffix = pickupBy != null
                        ? " Vui lòng nhận sách trước " + pickupBy + "."
                        : (dueInfo != null ? " Hạn trả dự kiến: " + dueInfo + "." : "");
                yield new ComposedNotification(
                        userId,
                        "LOAN_APPROVED",
                        "Yêu cầu mượn sách đã được duyệt",
                        "Phiếu mượn " + loanId + " (bản sao " + copyId + ") đã được duyệt." + suffix,
                        "LOAN",
                        loanId
                );
            }
            case TOPIC_LOAN_RETURNED -> {
                String loanId = requireString(payload, "loanId");
                String copyId = requireString(payload, "copyId");
                String returnedAt = requireString(payload, "returnedAt");
                yield new ComposedNotification(
                        userId,
                        "LOAN_RETURNED",
                        "Đã ghi nhận trả sách",
                        "Bản sao " + copyId + " thuộc phiếu mượn " + loanId + " đã được trả lúc " + returnedAt + ".",
                        "LOAN",
                        loanId
                );
            }
            case TOPIC_LOAN_OVERDUE -> {
                String loanId = requireString(payload, "loanId");
                String copyId = requireString(payload, "copyId");
                String dueAt = requireString(payload, "dueAt");
                yield new ComposedNotification(
                        userId,
                        "LOAN_OVERDUE",
                        "Phiếu mượn đã quá hạn",
                        "Bản sao " + copyId + " thuộc phiếu mượn " + loanId + " đã quá hạn từ " + dueAt
                                + ". Vui lòng hoàn trả sớm.",
                        "LOAN",
                        loanId
                );
            }
            case TOPIC_RESERVATION_READY -> {
                String reservationId = requireString(payload, "reservationId");
                String bookId = requireString(payload, "bookId");
                String copyId = requireString(payload, "copyId");
                String expiresAt = requireString(payload, "expiresAt");
                yield new ComposedNotification(
                        userId,
                        "RESERVATION_READY",
                        "Sách đặt trước đã sẵn sàng",
                        "Bản sao " + copyId + " của sách " + bookId + " đang được giữ cho bạn đến " + expiresAt + ".",
                        "RESERVATION",
                        reservationId
                );
            }
            default -> throw new IllegalArgumentException("Unsupported notification event type: " + event.type());
        };
    }

    private static String requireString(Map<String, Object> payload, String key) {
        Object value = payload.get(key);
        if (!(value instanceof String str) || str.isBlank()) {
            throw new IllegalArgumentException("Missing required payload field: " + key);
        }
        return str.trim();
    }

    private static String optionalString(Map<String, Object> payload, String key) {
        Object value = payload.get(key);
        return (value instanceof String str && !str.isBlank()) ? str.trim() : null;
    }
}
