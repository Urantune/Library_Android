package customer.notificationservice.service;

import customer.notificationservice.dto.NotificationDtos.DeviceTokenResponse;
import customer.notificationservice.entity.DeviceTokenEntity;
import customer.notificationservice.exception.NotificationException;
import customer.notificationservice.repository.DeviceTokenRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DeviceTokenService {
    private static final Set<String> SUPPORTED_PLATFORMS = Set.of("ANDROID");

    private final DeviceTokenRepository deviceTokens;
    private final Clock clock;

    public DeviceTokenService(DeviceTokenRepository deviceTokens, Clock clock) {
        this.deviceTokens = deviceTokens;
        this.clock = clock;
    }

    @Transactional
    public DeviceTokenResponse register(String userId, String token, String platform) {
        if (token == null || token.isBlank()) {
            throw new NotificationException(
                    HttpStatus.BAD_REQUEST,
                    "INVALID_DEVICE_TOKEN",
                    "FCM token is required",
                    Map.of("token", "FCM token is required")
            );
        }
        String normalizedPlatform = platform == null ? "" : platform.trim().toUpperCase(Locale.ROOT);
        if (!SUPPORTED_PLATFORMS.contains(normalizedPlatform)) {
            throw new NotificationException(
                    HttpStatus.BAD_REQUEST,
                    "INVALID_PLATFORM",
                    "Platform must be ANDROID",
                    Map.of("platform", "Platform must be ANDROID")
            );
        }

        String trimmedToken = token.trim();
        String now = Instant.now(clock).toString();
        DeviceTokenEntity entity = deviceTokens.findByFcmToken(trimmedToken)
                .map(existing -> {
                    existing.setUserId(userId);
                    existing.setPlatform(normalizedPlatform);
                    existing.setActive(1);
                    existing.setUpdatedAt(now);
                    return existing;
                })
                .orElseGet(() -> {
                    DeviceTokenEntity created = new DeviceTokenEntity();
                    created.setId(UUID.randomUUID().toString());
                    created.setUserId(userId);
                    created.setFcmToken(trimmedToken);
                    created.setPlatform(normalizedPlatform);
                    created.setActive(1);
                    created.setCreatedAt(now);
                    created.setUpdatedAt(now);
                    return created;
                });

        return DeviceTokenResponse.from(deviceTokens.saveAndFlush(entity));
    }

    @Transactional
    public void revoke(String id, String userId) {
        if (id == null || id.isBlank()) {
            throw new NotificationException(HttpStatus.NOT_FOUND, "DEVICE_TOKEN_NOT_FOUND", "Device token not found");
        }
        DeviceTokenEntity entity = deviceTokens.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new NotificationException(
                        HttpStatus.NOT_FOUND,
                        "DEVICE_TOKEN_NOT_FOUND",
                        "Device token not found"
                ));
        if (entity.getActive() != 0) {
            entity.setActive(0);
            entity.setUpdatedAt(Instant.now(clock).toString());
            deviceTokens.saveAndFlush(entity);
        }
    }

    @Transactional(readOnly = true)
    public List<String> findActiveTokensForUser(String userId) {
        return deviceTokens.findByUserIdAndActiveOrderByUpdatedAtDesc(userId, 1)
                .stream()
                .map(DeviceTokenEntity::getFcmToken)
                .toList();
    }
}
