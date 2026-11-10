package customer.notificationservice.service;

import customer.notificationservice.dto.NotificationDtos.ComposedNotification;

public interface PushSender {
    void send(String token, ComposedNotification notification);

    default boolean isEnabled() {
        return true;
    }
}
