package customer.notificationservice.repository;

import customer.notificationservice.entity.ProcessedEventEntity;
import customer.notificationservice.entity.ProcessedEventId;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProcessedEventRepository extends JpaRepository<ProcessedEventEntity, ProcessedEventId> {
}
