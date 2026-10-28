package customer.identityservice.auth.dto;

import jakarta.validation.constraints.*;

public final class AuthRequests {
    private AuthRequests() {}

    public record Register(
        @NotBlank @Email @Size(max=254) String email,
        @NotBlank @Size(min=8,max=72) String password,
        @NotBlank @Size(min=2,max=100) String fullName
    ) {}

    public record Login(
        @NotBlank @Email @Size(max=254) String email,
        @NotBlank @Size(max=72) String password
    ) {}

    public record Refresh(@NotBlank @Size(max=256) String refreshToken) {}
}
