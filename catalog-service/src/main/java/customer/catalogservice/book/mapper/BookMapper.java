package customer.catalogservice.book.mapper;

import customer.catalogservice.book.dto.BookResponse;
import customer.catalogservice.book.dto.BookResponse.NamedReference;
import customer.catalogservice.entity.Book;
import customer.catalogservice.entity.BookCopyStatus;
import java.util.Comparator;
import java.time.ZoneOffset;
import org.springframework.stereotype.Component;

@Component
public class BookMapper {
    public BookResponse toResponse(Book book) {
        var publisher = book.getPublisher();
        return new BookResponse(
            book.getId(), book.getIsbn(), book.getTitle(), book.getDescription(),
            book.getPublicationYear(), book.getLanguage(), book.getPageCount(),
            book.getCoverUrl(), book.getStatus().name(),
            publisher == null ? null : new NamedReference(publisher.getId(), publisher.getName()),
            book.getAuthors().stream().map(a -> new NamedReference(a.getId(), a.getName()))
                .sorted(Comparator.comparing(NamedReference::id)).toList(),
            book.getCategories().stream().map(c -> new NamedReference(c.getId(), c.getName()))
                .sorted(Comparator.comparing(NamedReference::id)).toList(),
            book.getCopies().size(),
            book.getCopies().stream().filter(c -> c.getStatus() == BookCopyStatus.AVAILABLE).count(),
            book.getCreatedAt().toInstant(ZoneOffset.UTC), book.getUpdatedAt().toInstant(ZoneOffset.UTC)
        );
    }
}
