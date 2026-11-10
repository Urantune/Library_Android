package customer.notificationservice.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import customer.notificationservice.exception.NotificationException;
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
import java.util.Base64;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;

@Component
public class NotificationJwtAuthResolver {
    private final ObjectMapper mapper;
    private final Resource publicKeyResource;
    private final String issuer;
    private final String audience;

    public NotificationJwtAuthResolver(
            ObjectMapper mapper,
            @Value("${security.jwt.public-key:file:data/auth-keys/public.pem}") Resource publicKeyResource,
            @Value("${security.jwt.issuer:library-identity}") String issuer,
            @Value("${security.jwt.audience:library-api}") String audience
    ) {
        this.mapper = mapper;
        this.publicKeyResource = publicKeyResource;
        this.issuer = issuer;
        this.audience = audience;
    }

    public AuthenticatedPrincipal requireAuthenticated(HttpServletRequest request) {
        String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authorization == null || authorization.isBlank()) {
            throw new NotificationException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "Missing Bearer token");
        }
        return verifyBearerToken(authorization);
    }

    @SuppressWarnings("unchecked")
    private AuthenticatedPrincipal verifyBearerToken(String authorization) {
        try {
            if (!authorization.startsWith("Bearer ")) {
                throw new SecurityException("Unsupported scheme");
            }
            String[] parts = authorization.substring(7).trim().split("\\.");
            if (parts.length != 3) {
                throw new SecurityException("Malformed JWT");
            }
            Map<String, Object> header = mapper.readValue(Base64.getUrlDecoder().decode(parts[0]), Map.class);
            if (!"RS256".equals(header.get("alg"))) {
                throw new SecurityException("Invalid alg");
            }
            PublicKey key = loadPublicKey();
            Signature verifier = Signature.getInstance("SHA256withRSA");
            verifier.initVerify(key);
            verifier.update((parts[0] + "." + parts[1]).getBytes(StandardCharsets.US_ASCII));
            if (!verifier.verify(Base64.getUrlDecoder().decode(parts[2]))) {
                throw new SecurityException("Invalid signature");
            }
            Map<String, Object> payload = mapper.readValue(Base64.getUrlDecoder().decode(parts[1]), Map.class);
            if (!(payload.get("sub") instanceof String subject) || subject.isBlank()) {
                throw new SecurityException("Missing sub");
            }
            if (!(payload.get("exp") instanceof Number exp) || exp.longValue() <= Instant.now().getEpochSecond()) {
                throw new SecurityException("Expired token");
            }
            if (issuer.isBlank() || !issuer.equals(payload.get("iss"))) {
                throw new SecurityException("Invalid issuer");
            }
            Object aud = payload.get("aud");
            boolean audValid = (aud instanceof String single && audience.equals(single))
                    || (aud instanceof Collection<?> col && col.contains(audience));
            if (!audValid) {
                throw new SecurityException("Invalid audience");
            }
            Object rawRoles = payload.get("roles");
            List<String> roles = rawRoles instanceof Collection<?> col
                    ? col.stream().map(String::valueOf).toList()
                    : rawRoles instanceof String single ? List.of(single) : List.of();
            return new AuthenticatedPrincipal(subject, roles);
        } catch (Exception ex) {
            throw new NotificationException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "Invalid or expired Bearer token");
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
                throw new SecurityException("Public key missing");
            }
            pem = Files.readString(fallback, StandardCharsets.UTF_8);
        }
        String sanitized = pem.replaceAll("-----BEGIN PUBLIC KEY-----|-----END PUBLIC KEY-----|\\s", "");
        return KeyFactory.getInstance("RSA")
                .generatePublic(new X509EncodedKeySpec(Base64.getDecoder().decode(sanitized)));
    }

    public record AuthenticatedPrincipal(String userId, List<String> roles) {
    }
}
