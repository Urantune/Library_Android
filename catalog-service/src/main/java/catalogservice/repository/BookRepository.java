package catalogservice.repository;

import catalogservice.entity.Book;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import catalogservice.enums.BookStatus;

public interface BookRepository extends JpaRepository<Book, String>, JpaSpecificationExecutor<Book> {
    java.util.Optional<Book> findByIsbn(String isbn);
    Page<Book> findByStatus(BookStatus status, Pageable pageable);
}
