package customer.catalogservice.book.dto;

import java.time.Instant;
import java.util.List;

public record BookResponse(
    String id, String isbn, String title, String description, Integer publicationYear,
    String language, Integer pageCount, String coverUrl, String status,
    NamedReference publisher, List<NamedReference> authors, List<NamedReference> categories,
    int totalCopies, long availableCopies, Instant createdAt, Instant updatedAt
) {
    public record NamedReference(String id, String name) {}
}
