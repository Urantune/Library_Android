package customer.catalogservice.book.dto;

import jakarta.validation.constraints.*;
import java.util.List;

public record BookWriteRequest(
    @NotBlank @Size(max = 255) String title,
    @NotBlank @Size(max = 32) String isbn,
    @Size(max = 20000) String description,
    @Min(1) @Max(9999) Integer publicationYear,
    @Size(max = 32) String language,
    @Positive Integer pageCount,
    @Size(max = 2048) String coverUrl,
    String publisherId,
    @Size(max = 50) List<@NotBlank String> authorIds,
    @Size(max = 50) List<@NotBlank String> categoryIds,
    String status
) {}
