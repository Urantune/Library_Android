package customer.identityservice.auth.dto;

import java.util.List;

public record SessionResponse(String accessToken, String refreshToken, String tokenType,
                              long expiresIn, UserView user) {
    public record UserView(String id, String email, String fullName, List<String> roles, String status) {}
}
