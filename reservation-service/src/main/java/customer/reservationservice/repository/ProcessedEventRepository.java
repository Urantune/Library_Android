package customer.reservationservice.repository;

import customer.reservationservice.entity.ProcessedEventEntity;
import customer.reservationservice.entity.ProcessedEventId;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProcessedEventRepository extends JpaRepository<ProcessedEventEntity, ProcessedEventId> {
}
