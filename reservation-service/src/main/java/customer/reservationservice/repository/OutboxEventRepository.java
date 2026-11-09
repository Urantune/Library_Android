package customer.reservationservice.repository;

import customer.reservationservice.entity.OutboxEventEntity;
import java.util.List;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface OutboxEventRepository extends JpaRepository<OutboxEventEntity, String> {
    @Query("""
            SELECT e
              FROM OutboxEventEntity e
             WHERE e.status = 'PENDING'
               AND (e.nextAttemptAt IS NULL OR e.nextAttemptAt <= :nowIso)
             ORDER BY e.createdAt ASC
            """)
    List<OutboxEventEntity> findDuePending(@Param("nowIso") String nowIso, Pageable pageable);
}
