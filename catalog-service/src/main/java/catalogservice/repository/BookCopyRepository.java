package catalogservice.repository;

import catalogservice.entity.BookCopy;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BookCopyRepository extends JpaRepository<BookCopy, String> { }
