package catalogservice.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PublisherInput(
        @NotBlank(message = "Publisher name is required")
        @Size(max = 200, message = "Publisher name must be at most 200 characters")
        String name,
        @Size(max = 500, message = "Address must be at most 500 characters")
        String address,
        @Email(message = "Email format is invalid")
        @Size(max = 254, message = "Email must be at most 254 characters")
        String email,
        @Size(max = 50, message = "Phone must be at most 50 characters")
        String phone,
        @Size(max = 500, message = "Website must be at most 500 characters")
        String website,
        String status
) {
}
