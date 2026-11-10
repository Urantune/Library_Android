package catalogservice.mapper;

import catalogservice.dto.response.BookResponse;
import catalogservice.entity.Book;
import catalogservice.enums.BookCopyStatus;
import java.time.ZoneOffset;
import org.springframework.stereotype.Component;

@Component
public class BookMapper {
    public BookResponse toResponse(Book book) {
        return new BookResponse(
            book.getId(), book.getIsbn(), book.getTitle(), book.getDescription(),
            book.getPublicationYear(), book.getLanguage(), book.getPageCount(),
            book.getCoverUrl(), book.getStatus().name(),
            book.getPublisher() == null ? null : new BookResponse.NamedReference(book.getPublisher().getId(), book.getPublisher().getName()),
            book.getAuthors().stream().map(a -> new BookResponse.NamedReference(a.getId(), a.getName())).toList(),
            book.getCategories().stream().map(c -> new BookResponse.NamedReference(c.getId(), c.getName())).toList(),
            book.getCopies().size(),
            book.getCopies().stream().filter(c -> c.getStatus() == BookCopyStatus.AVAILABLE).count(),
            book.getCreatedAt().toInstant(ZoneOffset.UTC), book.getUpdatedAt().toInstant(ZoneOffset.UTC)
        );
    }
}
