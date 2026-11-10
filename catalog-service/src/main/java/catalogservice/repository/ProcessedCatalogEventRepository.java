package catalogservice.repository;

import catalogservice.entity.ProcessedCatalogEvent;
import catalogservice.entity.ProcessedCatalogEventId;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProcessedCatalogEventRepository extends JpaRepository<ProcessedCatalogEvent, ProcessedCatalogEventId> {
}
