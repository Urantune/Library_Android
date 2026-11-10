package catalogservice.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record PublisherWriteRequest(
    @NotBlank @Size(max = 200) String name,
    @Size(max = 500) String address,
    @Email @Size(max = 254) String email,
    @Size(max = 50) String phone,
    @Size(max = 500) String website,
    @Pattern(regexp = "ACTIVE|INACTIVE", message = "Status must be ACTIVE or INACTIVE") String status
) {}
