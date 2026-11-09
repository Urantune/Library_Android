package catalogservice.repository;

import catalogservice.entity.Publisher;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface PublisherRepository extends JpaRepository<Publisher, String>, JpaSpecificationExecutor<Publisher> {
    boolean existsByNameIgnoreCase(String name);
}
