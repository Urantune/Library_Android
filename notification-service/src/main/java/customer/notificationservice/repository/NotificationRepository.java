package customer.notificationservice.repository;

import customer.notificationservice.entity.NotificationEntity;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NotificationRepository extends JpaRepository<NotificationEntity, String> {
    Page<NotificationEntity> findByUserIdAndChannel(String userId, String channel, Pageable pageable);

    Page<NotificationEntity> findByUserIdAndChannelAndIsRead(String userId, String channel, int isRead, Pageable pageable);

    long countByUserIdAndChannelAndIsRead(String userId, String channel, int isRead);

    Optional<NotificationEntity> findByIdAndUserIdAndChannel(String id, String userId, String channel);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            UPDATE NotificationEntity n
               SET n.isRead = 1, n.readAt = :readAt
             WHERE n.userId = :userId AND n.channel = 'IN_APP' AND n.isRead = 0
            """)
    int markAllInAppRead(@Param("userId") String userId, @Param("readAt") String readAt);
}
