package customer.notificationservice.service;

import customer.notificationservice.dto.NotificationDtos.MarkAllReadResponse;
import customer.notificationservice.dto.NotificationDtos.NotificationQuery;
import customer.notificationservice.dto.NotificationDtos.NotificationResponse;
import customer.notificationservice.dto.NotificationDtos.PageResponse;
import customer.notificationservice.dto.NotificationDtos.UnreadCountResponse;
import customer.notificationservice.entity.NotificationEntity;
import customer.notificationservice.exception.NotificationException;
import customer.notificationservice.repository.NotificationRepository;
import java.time.Clock;
import java.time.Instant;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationService {
    private static final String CHANNEL_IN_APP = "IN_APP";

    private final NotificationRepository notifications;
    private final Clock clock;

    public NotificationService(NotificationRepository notifications, Clock clock) {
        this.notifications = notifications;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public PageResponse<NotificationResponse> listMine(String userId, NotificationQuery query) {
        validatePagination(query.page(), query.size());
        var pageable = PageRequest.of(
                query.page(),
                query.size(),
                Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"))
        );
        Page<NotificationEntity> result = Boolean.TRUE.equals(query.unreadOnly())
                ? notifications.findByUserIdAndChannelAndIsRead(userId, CHANNEL_IN_APP, 0, pageable)
                : notifications.findByUserIdAndChannel(userId, CHANNEL_IN_APP, pageable);

        return new PageResponse<>(
                result.getContent().stream().map(NotificationResponse::from).toList(),
                query.page(),
                query.size(),
                result.getTotalElements(),
                result.getTotalPages()
        );
    }

    @Transactional(readOnly = true)
    public UnreadCountResponse unreadCount(String userId) {
        long count = notifications.countByUserIdAndChannelAndIsRead(userId, CHANNEL_IN_APP, 0);
        return new UnreadCountResponse(count);
    }

    @Transactional
    public NotificationResponse markRead(String id, String userId) {
        if (id == null || id.isBlank()) {
            throw notFound();
        }
        // Owner-only: notifications belonging to another user MUST return 404 to prevent ID enumeration
        NotificationEntity entity = notifications.findByIdAndUserIdAndChannel(id, userId, CHANNEL_IN_APP)
                .orElseThrow(this::notFound);
        if (entity.getIsRead() == 0) {
            entity.setIsRead(1);
            entity.setReadAt(Instant.now(clock).toString());
            entity = notifications.saveAndFlush(entity);
        }
        return NotificationResponse.from(entity);
    }

    @Transactional
    public MarkAllReadResponse markAllRead(String userId) {
        int updated = notifications.markAllInAppRead(userId, Instant.now(clock).toString());
        return new MarkAllReadResponse(updated);
    }

    private void validatePagination(int page, int size) {
        if (page < 0 || size < 1 || size > 100) {
            throw new NotificationException(
                    HttpStatus.BAD_REQUEST,
                    "INVALID_PAGINATION",
                    "Page must be >= 0 and size between 1 and 100"
            );
        }
    }

    private NotificationException notFound() {
        return new NotificationException(HttpStatus.NOT_FOUND, "NOTIFICATION_NOT_FOUND", "Notification not found");
    }
}
