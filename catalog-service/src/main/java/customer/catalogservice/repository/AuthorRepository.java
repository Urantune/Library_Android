package customer.catalogservice.repository;

import customer.catalogservice.entity.Author;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AuthorRepository extends JpaRepository<Author, String> { }
