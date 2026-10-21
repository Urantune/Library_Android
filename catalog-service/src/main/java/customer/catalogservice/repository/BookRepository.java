package customer.catalogservice.repository;

import customer.catalogservice.entity.Book;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import customer.catalogservice.entity.BookStatus;

public interface BookRepository extends JpaRepository<Book, String> {
    java.util.Optional<Book> findByIsbn(String isbn);
    Page<Book> findByStatus(BookStatus status, Pageable pageable);
}
