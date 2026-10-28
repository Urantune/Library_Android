package customer.identityservice.auth.web;

import customer.identityservice.auth.dto.*;
import customer.identityservice.auth.persistence.AuthRepository;
import customer.identityservice.auth.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
public class AuthController {
    private final AuthService service;
    private final AuthRepository repository;
    public AuthController(AuthService service, AuthRepository repository) { this.service=service;this.repository=repository; }

    @PostMapping(value="/api/auth/register",consumes="application/json")
    public ResponseEntity<ApiResponse<SessionResponse.UserView>> register(@Valid @RequestBody AuthRequests.Register input, HttpServletRequest request) {
        return ResponseEntity.status(201).body(ApiResponse.success(201,service.register(input),AuthErrorWriter.trace(request)));
    }

    @PostMapping(value="/api/auth/login",consumes="application/json")
    public ApiResponse<SessionResponse> login(@Valid @RequestBody AuthRequests.Login input, HttpServletRequest request) {
        return ApiResponse.success(200,service.login(input),AuthErrorWriter.trace(request));
    }

    @PostMapping(value="/api/auth/refresh",consumes="application/json")
    public ApiResponse<SessionResponse> refresh(@Valid @RequestBody AuthRequests.Refresh input, HttpServletRequest request) {
        return ApiResponse.success(200,service.refresh(input.refreshToken()),AuthErrorWriter.trace(request));
    }

    @PostMapping("/api/auth/logout")
    public ResponseEntity<Void> logout(@AuthenticationPrincipal Jwt jwt) {
        service.logout(jwt.getClaimAsString("sid"));
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/api/users/me")
    public ApiResponse<SessionResponse.UserView> me(@AuthenticationPrincipal Jwt jwt,HttpServletRequest request) {
        return ApiResponse.success(200,repository.view(jwt.getSubject()),AuthErrorWriter.trace(request));
    }
}
