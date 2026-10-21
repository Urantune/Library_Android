package customer.catalogservice.repository;

import customer.catalogservice.entity.Publisher;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PublisherRepository extends JpaRepository<Publisher, String> { }
