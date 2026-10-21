package customer.catalogservice.repository;

import customer.catalogservice.entity.BookCopy;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BookCopyRepository extends JpaRepository<BookCopy, String> { }
