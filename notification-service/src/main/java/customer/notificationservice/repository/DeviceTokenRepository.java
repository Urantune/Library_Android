package customer.notificationservice.repository;

import customer.notificationservice.entity.DeviceTokenEntity;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceTokenRepository extends JpaRepository<DeviceTokenEntity, String> {
    Optional<DeviceTokenEntity> findByFcmToken(String fcmToken);

    Optional<DeviceTokenEntity> findByIdAndUserId(String id, String userId);

    List<DeviceTokenEntity> findByUserIdAndActiveOrderByUpdatedAtDesc(String userId, int active);
}
