package customer.reservationservice.repository;

import customer.reservationservice.entity.IdempotencyRecordEntity;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IdempotencyRecordRepository extends JpaRepository<IdempotencyRecordEntity, String> {
    Optional<IdempotencyRecordEntity> findByActorIdAndOperationAndIdempotencyKey(
            String actorId,
            String operation,
            String idempotencyKey
    );
}
