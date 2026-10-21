package customer.catalogservice.book.mapper;

import customer.catalogservice.book.dto.BookResponse;
import customer.catalogservice.entity.Book;
import customer.catalogservice.entity.BookCopyStatus;
import java.time.ZoneOffset;
import org.springframework.stereotype.Component;

@Component
public class BookMapper {
    public BookResponse toResponse(Book book) {
        return new BookResponse(
            book.getId(), book.getIsbn(), book.getTitle(), book.getDescription(),
            book.getPublicationYear(), book.getLanguage(), book.getPageCount(),
            book.getCoverUrl(), book.getStatus().name(),
            null, null, null,
            book.getCopies().size(),
            book.getCopies().stream().filter(c -> c.getStatus() == BookCopyStatus.AVAILABLE).count(),
            book.getCreatedAt().toInstant(ZoneOffset.UTC), book.getUpdatedAt().toInstant(ZoneOffset.UTC)
        );
    }
}
