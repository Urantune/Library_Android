package catalogservice.config;

import catalogservice.exception.PublisherException;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.X509EncodedKeySpec;
import java.time.Instant;
import java.util.Arrays;
import java.util.Base64;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;

@Component
public class PublisherAuthGuard {
    private static final Set<String> STAFF_ROLES = Set.of("LIBRARIAN", "ADMIN");

    private final ObjectMapper mapper;
    private final Resource publicKeyResource;
    private final String issuer;
    private final String audience;
    private final boolean requireJwt;

    public PublisherAuthGuard(
            ObjectMapper mapper,
            @Value("${security.jwt.public-key:file:data/auth-keys/public.pem}") Resource publicKeyResource,
            @Value("${security.jwt.issuer:library-identity}") String issuer,
            @Value("${security.jwt.audience:library-api}") String audience,
            @Value("${app.security.require-jwt:false}") boolean requireJwt
    ) {
        this.mapper = mapper;
        this.publicKeyResource = publicKeyResource;
        this.issuer = issuer;
        this.audience = audience;
        this.requireJwt = requireJwt;
    }

    public void authorizeRead(HttpServletRequest request) {
        String authHeader = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authHeader != null && !authHeader.isBlank()) {
            verifyBearerToken(authHeader);
            return;
        }
        if (requireJwt) {
            throw new PublisherException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "Missing Bearer token");
        }
    }

    public void authorizeStaffWrite(HttpServletRequest request) {
        String authHeader = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authHeader != null && !authHeader.isBlank()) {
            VerifiedClaims claims = verifyBearerToken(authHeader);
            if (claims.roles().stream().noneMatch(STAFF_ROLES::contains)) {
                throw new PublisherException(HttpStatus.FORBIDDEN, "FORBIDDEN", "Staff role (LIBRARIAN or ADMIN) is required");
            }
            return;
        }
        String gatewayRoles = request.getHeader("X-User-Roles");
        if (gatewayRoles != null && !gatewayRoles.isBlank()) {
            boolean isStaff = Arrays.stream(gatewayRoles.split(","))
                    .map(String::trim)
                    .anyMatch(STAFF_ROLES::contains);
            if (!isStaff) {
                throw new PublisherException(HttpStatus.FORBIDDEN, "FORBIDDEN", "Staff role (LIBRARIAN or ADMIN) is required");
            }
            return;
        }
        if (requireJwt) {
            throw new PublisherException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "Missing Bearer token");
        }
    }

    @SuppressWarnings("unchecked")
    private VerifiedClaims verifyBearerToken(String authorization) {
        try {
            if (!authorization.startsWith("Bearer ")) {
                throw new SecurityException("Unsupported authorization scheme");
            }
            String[] parts = authorization.substring(7).trim().split("\\.");
            if (parts.length != 3) {
                throw new SecurityException("Malformed JWT");
            }
            Map<String, Object> header = mapper.readValue(Base64.getUrlDecoder().decode(parts[0]), Map.class);
            if (!"RS256".equals(header.get("alg"))) {
                throw new SecurityException("Unsupported JWT algorithm");
            }
            PublicKey key = loadPublicKey();
            Signature verifier = Signature.getInstance("SHA256withRSA");
            verifier.initVerify(key);
            verifier.update((parts[0] + "." + parts[1]).getBytes(StandardCharsets.US_ASCII));
            if (!verifier.verify(Base64.getUrlDecoder().decode(parts[2]))) {
                throw new SecurityException("Invalid JWT signature");
            }
            Map<String, Object> payload = mapper.readValue(Base64.getUrlDecoder().decode(parts[1]), Map.class);
            if (!(payload.get("sub") instanceof String subject) || subject.isBlank()) {
                throw new SecurityException("Missing JWT subject");
            }
            if (!(payload.get("exp") instanceof Number exp) || exp.longValue() <= Instant.now().getEpochSecond()) {
                throw new SecurityException("JWT expired");
            }
            if (issuer.isBlank() || !issuer.equals(payload.get("iss"))) {
                throw new SecurityException("Invalid JWT issuer");
            }
            Object aud = payload.get("aud");
            boolean audValid = (aud instanceof String value && audience.equals(value))
                    || (aud instanceof Collection<?> values && values.contains(audience));
            if (!audValid) {
                throw new SecurityException("Invalid JWT audience");
            }
            Object rawRoles = payload.get("roles");
            List<String> roles = rawRoles instanceof Collection<?> list
                    ? list.stream().map(String::valueOf).toList()
                    : rawRoles instanceof String single ? List.of(single) : List.of();
            return new VerifiedClaims(subject, roles);
        } catch (Exception ex) {
            throw new PublisherException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "Invalid or expired Bearer token");
        }
    }

    private PublicKey loadPublicKey() throws Exception {
        String pem;
        if (publicKeyResource.exists()) {
            try (InputStream in = publicKeyResource.getInputStream()) {
                pem = StreamUtils.copyToString(in, StandardCharsets.UTF_8);
            }
        } else {
            Path fallback = Path.of("../data/auth-keys/public.pem");
            if (!Files.exists(fallback)) {
                throw new SecurityException("Public key not found");
            }
            pem = Files.readString(fallback, StandardCharsets.UTF_8);
        }
        String sanitized = pem.replaceAll("-----BEGIN PUBLIC KEY-----|-----END PUBLIC KEY-----|\\s", "");
        return KeyFactory.getInstance("RSA")
                .generatePublic(new X509EncodedKeySpec(Base64.getDecoder().decode(sanitized)));
    }

    private record VerifiedClaims(String subject, List<String> roles) {
    }
}
