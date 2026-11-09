package customer.notificationservice.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import customer.notificationservice.dto.NotificationDtos.ComposedNotification;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;

/** Sends FCM v1 notifications using a service-account JSON file or a supplied OAuth token. */
@Component
@ConditionalOnMissingBean(name = "customPushSender")
public class FcmPushSender implements PushSender {
    private static final Logger log = LoggerFactory.getLogger(FcmPushSender.class);
    private static final String FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
    private static final String JWT_GRANT = "urn:ietf:params:oauth:grant-type:jwt-bearer";

    private final boolean enabled;
    private final String credentialsPath;
    private final String configuredProjectId;
    private final String endpointBaseUrl;
    private final String configuredAccessToken;
    private final ObjectMapper mapper;
    private final Clock clock;
    private final RestClient restClient;
    private volatile CachedToken cachedToken;

    public FcmPushSender(
            ObjectMapper mapper,
            @Value("${app.fcm.enabled:false}") boolean enabled,
            @Value("${app.fcm.credentials-path:}") String credentialsPath,
            @Value("${app.fcm.project-id:}") String projectId,
            @Value("${app.fcm.endpoint-base-url:https://fcm.googleapis.com}") String endpointBaseUrl,
            @Value("${app.fcm.access-token:}") String accessToken,
            Clock clock
    ) {
        this.mapper = mapper;
        this.enabled = enabled;
        this.credentialsPath = credentialsPath;
        this.configuredProjectId = projectId;
        this.endpointBaseUrl = endpointBaseUrl;
        this.configuredAccessToken = accessToken;
        this.clock = clock;
        this.restClient = RestClient.builder().baseUrl(endpointBaseUrl).build();
    }

    @Override
    public boolean isEnabled() {
        return enabled && (hasServiceAccountFile() || hasConfiguredAccessToken());
    }

    @Override
    public void send(String token, ComposedNotification notification) {
        if (!isEnabled()) {
            log.debug("FCM disabled or credentials absent; skipping push for user={}", notification.userId());
            return;
        }
        try {
            ServiceAccount account = serviceAccount();
            String projectId = firstNonBlank(configuredProjectId, account == null ? null : account.projectId());
            if (projectId == null) {
                throw new IllegalStateException("FCM project ID is missing from configuration and service-account JSON");
            }
            String bearer = account == null ? configuredAccessToken : accessToken(account);
            Map<String, Object> body = Map.of(
                    "message", Map.of(
                            "token", token,
                            "notification", Map.of("title", notification.title(), "body", notification.body()),
                            "data", Map.of(
                                    "type", notification.type(),
                                    "referenceType", notification.referenceType() == null ? "" : notification.referenceType(),
                                    "referenceId", notification.referenceId() == null ? "" : notification.referenceId()
                            )
                    )
            );
            restClient.post()
                    .uri("/v1/projects/{projectId}/messages:send", projectId)
                    .header("Authorization", "Bearer " + bearer)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .toBodilessEntity();
        } catch (RuntimeException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new IllegalStateException("FCM push request failed", ex);
        }
    }

    private String accessToken(ServiceAccount account) throws Exception {
        CachedToken current = cachedToken;
        Instant now = Instant.now(clock);
        if (current != null && current.expiresAt().isAfter(now.plusSeconds(60))) return current.value();
        synchronized (this) {
            current = cachedToken;
            now = Instant.now(clock);
            if (current != null && current.expiresAt().isAfter(now.plusSeconds(60))) return current.value();
            String assertion = createAssertion(account, now);
            MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
            form.add("grant_type", JWT_GRANT);
            form.add("assertion", assertion);
            String rawResponse = RestClient.create()
                    .post()
                    .uri(account.tokenUri())
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(form)
                    .retrieve()
                    .body(String.class);
            Map<String, Object> response = rawResponse == null ? null
                    : mapper.readValue(rawResponse, new TypeReference<>() { });
            if (response == null || !(response.get("access_token") instanceof String value) || value.isBlank()) {
                throw new IllegalStateException("Google OAuth response did not contain an access token");
            }
            long lifetime = response.get("expires_in") instanceof Number number ? number.longValue() : 3600L;
            cachedToken = new CachedToken(value, now.plusSeconds(Math.max(60L, lifetime)));
            return value;
        }
    }

    private String createAssertion(ServiceAccount account, Instant now) throws Exception {
        long issuedAt = now.getEpochSecond();
        Map<String, Object> header = Map.of("alg", "RS256", "typ", "JWT");
        Map<String, Object> claims = new LinkedHashMap<>();
        claims.put("iss", account.clientEmail());
        claims.put("scope", FCM_SCOPE);
        claims.put("aud", account.tokenUri());
        claims.put("iat", issuedAt);
        claims.put("exp", issuedAt + 3600);
        String unsigned = base64Json(header) + "." + base64Json(claims);
        Signature signer = Signature.getInstance("SHA256withRSA");
        signer.initSign(privateKey(account.privateKeyPem()));
        signer.update(unsigned.getBytes(StandardCharsets.US_ASCII));
        return unsigned + "." + Base64.getUrlEncoder().withoutPadding().encodeToString(signer.sign());
    }

    private String base64Json(Object value) throws IOException {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(mapper.writeValueAsBytes(value));
    }

    private ServiceAccount serviceAccount() throws IOException {
        if (!hasServiceAccountFile()) return null;
        Map<String, Object> json = mapper.readValue(
                Files.readString(Path.of(credentialsPath), StandardCharsets.UTF_8),
                new TypeReference<>() { });
        String tokenUri = stringValue(json.get("token_uri"));
        if (tokenUri == null || !tokenUri.startsWith("https://")) {
            throw new IllegalArgumentException("Service-account token_uri must use HTTPS");
        }
        String email = stringValue(json.get("client_email"));
        String privateKeyPem = stringValue(json.get("private_key"));
        if (email == null || privateKeyPem == null) {
            throw new IllegalArgumentException("Service-account JSON is missing client_email or private_key");
        }
        return new ServiceAccount(stringValue(json.get("project_id")), email, privateKeyPem, tokenUri);
    }

    private static PrivateKey privateKey(String pem) throws Exception {
        String sanitized = pem.replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s", "");
        byte[] encoded = Base64.getDecoder().decode(sanitized);
        return KeyFactory.getInstance("RSA").generatePrivate(new PKCS8EncodedKeySpec(encoded));
    }

    private boolean hasServiceAccountFile() {
        return credentialsPath != null && !credentialsPath.isBlank() && Files.isRegularFile(Path.of(credentialsPath));
    }

    private boolean hasConfiguredAccessToken() {
        return configuredAccessToken != null && !configuredAccessToken.isBlank()
                && configuredProjectId != null && !configuredProjectId.isBlank();
    }

    private static String stringValue(Object value) {
        return value instanceof String text && !text.isBlank() ? text.trim() : null;
    }

    private static String firstNonBlank(String first, String second) {
        if (first != null && !first.isBlank()) return first.trim();
        return second == null || second.isBlank() ? null : second.trim();
    }

    private record ServiceAccount(String projectId, String clientEmail, String privateKeyPem, String tokenUri) {
    }

    private record CachedToken(String value, Instant expiresAt) {
    }
}
