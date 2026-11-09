package customer.circulationservice.repository;

import customer.circulationservice.entity.CirculationOutboxEvent;
import java.util.List;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CirculationOutboxRepository extends JpaRepository<CirculationOutboxEvent, String> {
    @Query("select e from CirculationOutboxEvent e where e.status = 'PENDING' and (e.nextAttemptAt is null or e.nextAttemptAt <= :now) order by e.createdAt asc")
    List<CirculationOutboxEvent> findDuePending(@Param("now") String now, Pageable pageable);
}
