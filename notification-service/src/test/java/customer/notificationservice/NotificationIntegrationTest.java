package customer.notificationservice;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import customer.notificationservice.dto.NotificationDtos.ComposedNotification;
import customer.notificationservice.messaging.NotificationEventConsumer;
import customer.notificationservice.service.PushSender;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.Signature;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@SpringBootTest(
        classes = {NotificationServiceApplication.class, NotificationIntegrationTest.ControllablePushConfig.class},
        properties = {
            "eureka.client.enabled=false",
            "spring.cloud.discovery.enabled=false",
            "spring.kafka.listener.auto-startup=false"
        }
)
class NotificationIntegrationTest {
    private static final String DB = "jdbc:sqlite:target/notification-it-" + UUID.randomUUID() + ".db";
    private static final ObjectMapper JSON = new ObjectMapper();
    private static Path publicKeyPath;
    private static PrivateKey privateKey;

    static final AtomicBoolean PUSH_ENABLED = new AtomicBoolean(false);
    static final AtomicBoolean PUSH_SHOULD_THROW = new AtomicBoolean(false);
    static final AtomicInteger PUSH_CALLS = new AtomicInteger(0);

    @TestConfiguration
    static class ControllablePushConfig {
        @Bean(name = "customPushSender")
        @Primary
        PushSender controllablePushSender() {
            return new PushSender() {
                @Override
                public boolean isEnabled() {
                    return PUSH_ENABLED.get();
                }

                @Override
                public void send(String token, ComposedNotification notification) {
                    PUSH_CALLS.incrementAndGet();
                    if (PUSH_SHOULD_THROW.get()) {
                        throw new RuntimeException("Simulated FCM outage");
                    }
                }
            };
        }
    }

    @Autowired WebApplicationContext context;
    @Autowired JdbcTemplate jdbc;
    @Autowired NotificationEventConsumer consumer;
    private MockMvc mvc;

    @BeforeAll
    static void generateKeys() throws Exception {
        KeyPairGenerator gen = KeyPairGenerator.getInstance("RSA");
        gen.initialize(2048);
        KeyPair pair = gen.generateKeyPair();
        privateKey = pair.getPrivate();
        String pem = "-----BEGIN PUBLIC KEY-----\n"
                + Base64.getMimeEncoder(64, "\n".getBytes(StandardCharsets.US_ASCII))
                        .encodeToString(pair.getPublic().getEncoded())
                + "\n-----END PUBLIC KEY-----\n";
        publicKeyPath = Path.of("target", "notif-pub-" + UUID.randomUUID() + ".pem");
        Files.createDirectories(publicKeyPath.getParent());
        Files.writeString(publicKeyPath, pem, StandardCharsets.UTF_8);
    }

    @DynamicPropertySource
    static void registerProps(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", () -> DB);
        registry.add("security.jwt.public-key", () -> "file:" + publicKeyPath.toAbsolutePath());
    }

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).build();
        jdbc.update("DELETE FROM processed_events");
        jdbc.update("DELETE FROM notifications");
        jdbc.update("DELETE FROM device_tokens");
        PUSH_ENABLED.set(false);
        PUSH_SHOULD_THROW.set(false);
        PUSH_CALLS.set(0);
    }

    @Test
    void consumesAllEventTypesDeduplicatesReplayAndWorksWhenFcmDisabled() throws Exception {
        String userA = "user-a";
        String jwtA = signJwt(userA, List.of("MEMBER"));

        String approvedEvent = """
                {
                  "eventId": "evt-approved-1",
                  "type": "library.loan.approved.v1",
                  "schemaVersion": 1,
                  "occurredAt": "2026-11-08T09:00:00Z",
                  "traceId": "tr-1",
                  "aggregateId": "loan-101",
                  "aggregateVersion": 1,
                  "payload": {
                    "loanId": "loan-101",
                    "userId": "user-a",
                    "bookId": "book-1",
                    "copyId": "copy-1",
                    "approvedAt": "2026-11-08T09:00:00Z",
                    "pickupBy": "2026-11-09T09:00:00Z"
                  }
                }
                """;
        String returnedEvent = """
                {
                  "eventId": "evt-returned-1",
                  "type": "library.loan.returned.v1",
                  "schemaVersion": 1,
                  "occurredAt": "2026-11-08T10:00:00Z",
                  "traceId": "tr-2",
                  "aggregateId": "loan-101",
                  "aggregateVersion": 2,
                  "payload": {
                    "loanId": "loan-101",
                    "userId": "user-a",
                    "bookId": "book-1",
                    "copyId": "copy-1",
                    "returnedAt": "2026-11-08T10:00:00Z",
                    "condition": "GOOD"
                  }
                }
                """;
        String overdueEvent = """
                {
                  "eventId": "evt-overdue-1",
                  "type": "library.loan.overdue.v1",
                  "schemaVersion": 1,
                  "occurredAt": "2026-11-08T11:00:00Z",
                  "traceId": "tr-3",
                  "aggregateId": "loan-102",
                  "aggregateVersion": 3,
                  "payload": {
                    "loanId": "loan-102",
                    "userId": "user-a",
                    "bookId": "book-2",
                    "copyId": "copy-2",
                    "dueAt": "2026-11-07T23:59:59Z",
                    "detectedAt": "2026-11-08T11:00:00Z"
                  }
                }
                """;
        String readyEvent = """
                {
                  "eventId": "evt-ready-1",
                  "type": "library.reservation.ready.v1",
                  "schemaVersion": 1,
                  "occurredAt": "2026-11-08T12:00:00Z",
                  "traceId": "tr-4",
                  "aggregateId": "res-501",
                  "aggregateVersion": 2,
                  "payload": {
                    "reservationId": "res-501",
                    "userId": "user-a",
                    "bookId": "book-3",
                    "copyId": "copy-9",
                    "readyAt": "2026-11-08T12:00:00Z",
                    "expiresAt": "2026-11-09T12:00:00Z"
                  }
                }
                """;

        consumer.onLoanApproved(approvedEvent);
        consumer.onLoanApproved(approvedEvent); // Replay must NOT duplicate!
        consumer.onLoanReturned(returnedEvent);
        consumer.onOverdue(overdueEvent);
        consumer.onReservationReady(readyEvent);
        consumer.onReservationReady(readyEvent); // Replay must NOT duplicate!

        assertThat(PUSH_CALLS.get()).isZero(); // FCM disabled

        mvc.perform(get("/api/notifications/unread-count").header("Authorization", "Bearer " + jwtA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.unreadCount").value(4));

        mvc.perform(get("/api/notifications").header("Authorization", "Bearer " + jwtA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(4));
    }

    @Test
    void pushFailureDoesNotRollbackCommittedInAppNotificationAndOwnerIsolationReturns404() throws Exception {
        String jwtA = signJwt("user-a", List.of("MEMBER"));
        String jwtB = signJwt("user-b", List.of("MEMBER"));

        // Register FCM device token for user-a
        String tokenResp = mvc.perform(post("/api/notifications/device-tokens")
                        .header("Authorization", "Bearer " + jwtA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"token\":\"fcm-token-xyz-001\",\"platform\":\"ANDROID\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.active").value(true))
                .andReturn().getResponse().getContentAsString();
        String tokenId = JSON.readTree(tokenResp).path("data").path("id").asText();

        // Enable push AND simulate FCM runtime failure
        PUSH_ENABLED.set(true);
        PUSH_SHOULD_THROW.set(true);

        consumer.onReservationReady("""
                {
                  "eventId": "evt-push-fail-1",
                  "type": "library.reservation.ready.v1",
                  "schemaVersion": 1,
                  "occurredAt": "2026-11-08T13:00:00Z",
                  "traceId": "tr-push",
                  "aggregateId": "res-777",
                  "aggregateVersion": 2,
                  "payload": {
                    "reservationId": "res-777",
                    "userId": "user-a",
                    "bookId": "book-7",
                    "copyId": "copy-7",
                    "readyAt": "2026-11-08T13:00:00Z",
                    "expiresAt": "2026-11-09T13:00:00Z"
                  }
                }
                """);

        assertThat(PUSH_CALLS.get()).isEqualTo(1);

        // IN_APP notification MUST still be persisted despite FCM failure!
        String listResp = mvc.perform(get("/api/notifications").header("Authorization", "Bearer " + jwtA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.items[0].referenceType").value("RESERVATION"))
                .andExpect(jsonPath("$.data.items[0].referenceId").value("res-777"))
                .andReturn().getResponse().getContentAsString();
        String notifId = JSON.readTree(listResp).path("data").path("items").get(0).path("id").asText();

        // Acceptance rule: another user accessing/marking user-a's notification or device token MUST get 404!
        mvc.perform(patch("/api/notifications/" + notifId + "/read")
                        .header("Authorization", "Bearer " + jwtB))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("NOTIFICATION_NOT_FOUND"));

        mvc.perform(delete("/api/notifications/device-tokens/" + tokenId)
                        .header("Authorization", "Bearer " + jwtB))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("DEVICE_TOKEN_NOT_FOUND"));

        // Owner marks read & revokes device token successfully
        mvc.perform(patch("/api/notifications/" + notifId + "/read")
                        .header("Authorization", "Bearer " + jwtA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.isRead").value(true));

        mvc.perform(get("/api/notifications/unread-count").header("Authorization", "Bearer " + jwtA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.unreadCount").value(0));

        mvc.perform(delete("/api/notifications/device-tokens/" + tokenId)
                        .header("Authorization", "Bearer " + jwtA))
                .andExpect(status().isNoContent());

        assertThat(jdbc.queryForObject("SELECT active FROM device_tokens WHERE id = ?", Integer.class, tokenId))
                .isZero();
    }

    @Test
    void markAllReadAndMissingTokenReturnExpectedStatuses() throws Exception {
        mvc.perform(get("/api/notifications")).andExpect(status().isUnauthorized());

        String jwtA = signJwt("user-mark-all", List.of("MEMBER"));
        for (int i = 1; i <= 2; i++) {
            consumer.onLoanApproved("""
                    {
                      "eventId": "evt-ma-%d",
                      "type": "library.loan.approved.v1",
                      "schemaVersion": 1,
                      "occurredAt": "2026-11-08T09:00:00Z",
                      "traceId": "tr-ma",
                      "aggregateId": "loan-%d",
                      "aggregateVersion": 1,
                      "payload": {
                        "loanId": "loan-%d",
                        "userId": "user-mark-all",
                        "bookId": "book-1",
                        "copyId": "copy-%d",
                        "approvedAt": "2026-11-08T09:00:00Z"
                      }
                    }
                    """.formatted(i, i, i, i));
        }

        mvc.perform(patch("/api/notifications/read-all").header("Authorization", "Bearer " + jwtA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.updatedCount").value(2));

        mvc.perform(get("/api/notifications").param("unreadOnly", "true").header("Authorization", "Bearer " + jwtA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(0));
    }

    private static String signJwt(String sub, List<String> roles) throws Exception {
        String headerJson = JSON.writeValueAsString(Map.of("alg", "RS256", "typ", "JWT"));
        String payloadJson = JSON.writeValueAsString(Map.of(
                "iss", "library-identity",
                "aud", List.of("library-api"),
                "sub", sub,
                "roles", roles,
                "exp", Instant.now().plusSeconds(600).getEpochSecond()
        ));
        String encodedHeader = Base64.getUrlEncoder().withoutPadding().encodeToString(headerJson.getBytes(StandardCharsets.UTF_8));
        String encodedPayload = Base64.getUrlEncoder().withoutPadding().encodeToString(payloadJson.getBytes(StandardCharsets.UTF_8));
        Signature sig = Signature.getInstance("SHA256withRSA");
        sig.initSign(privateKey);
        sig.update((encodedHeader + "." + encodedPayload).getBytes(StandardCharsets.US_ASCII));
        String encodedSig = Base64.getUrlEncoder().withoutPadding().encodeToString(sig.sign());
        return encodedHeader + "." + encodedPayload + "." + encodedSig;
    }
}
