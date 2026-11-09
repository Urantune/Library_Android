package catalogservice.repository;

import catalogservice.entity.CatalogOutboxEvent;
import java.util.List;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CatalogOutboxRepository extends JpaRepository<CatalogOutboxEvent, String> {
    @Query("select e from CatalogOutboxEvent e where e.status = 'PENDING' and (e.nextAttemptAt is null or e.nextAttemptAt <= :now) order by e.createdAt asc")
    List<CatalogOutboxEvent> findDuePending(@Param("now") String now, Pageable pageable);
}
