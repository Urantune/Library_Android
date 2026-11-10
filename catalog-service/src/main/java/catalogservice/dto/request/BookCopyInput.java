package catalogservice.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record BookCopyInput(@NotBlank @Size(max = 80) String code,
                            @Size(max = 120) String shelfLocation) {}
