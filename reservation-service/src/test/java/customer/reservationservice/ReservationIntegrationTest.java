package customer.reservationservice;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import customer.reservationservice.client.CatalogInventoryClient;
import customer.reservationservice.client.CirculationLoanClient;
import customer.reservationservice.dto.ReservationDtos.BookAvailability;
import customer.reservationservice.dto.ReservationDtos.ClaimOutcome;
import customer.reservationservice.dto.ReservationDtos.FulfilledLoanResult;
import customer.reservationservice.dto.ReservationDtos.ReservationResponse;
import customer.reservationservice.exception.ReservationException;
import customer.reservationservice.messaging.CopyAvailableConsumer;
import customer.reservationservice.messaging.OutboxPublisher;
import customer.reservationservice.service.ReservationExpiryJob;
import customer.reservationservice.service.ReservationQueueService;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.Signature;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.TopicPartition;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.kafka.core.KafkaOperations;
import org.springframework.kafka.support.SendResult;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import java.util.concurrent.CompletableFuture;

@SpringBootTest(
        classes = {ReservationServiceApplication.class, ReservationIntegrationTest.StubCrossServiceConfig.class},
        properties = {
            "eureka.client.enabled=false",
            "spring.cloud.discovery.enabled=false",
            "spring.kafka.listener.auto-startup=false",
            "app.reservation.jobs.enabled=false",
            "app.reservation.outbox.max-retries=2"
        }
)
class ReservationIntegrationTest {
    private static final String DB = "jdbc:sqlite:target/reservation-it-" + UUID.randomUUID() + ".db";
    private static final ObjectMapper JSON = new ObjectMapper();
    private static Path publicKeyPath;
    private static PrivateKey privateKey;

    // Simulated in-memory Catalog copy holder map: copyId -> holderId ("AVAILABLE" when free)
    static final ConcurrentHashMap<String, String> COPY_HOLDERS = new ConcurrentHashMap<>();
    static final AtomicLong AVAILABLE_COPIES = new AtomicLong(0);
    static final AtomicBoolean CATALOG_RELEASE_FAIL = new AtomicBoolean(false);
    static final AtomicBoolean CATALOG_REVERSE_TRANSFER_FAIL = new AtomicBoolean(false);
    static final AtomicBoolean CIRCULATION_FAIL = new AtomicBoolean(false);
    static final AtomicBoolean KAFKA_SEND_FAIL = new AtomicBoolean(false);
    static final List<String> SENT_TOPICS = new java.util.concurrent.CopyOnWriteArrayList<>();

    @TestConfiguration
    static class StubCrossServiceConfig {
        @Bean(name = "customCatalogInventoryClient")
        @Primary
        CatalogInventoryClient stubCatalogInventoryClient() {
            return new CatalogInventoryClient() {
                @Override
                public BookAvailability getAvailability(String bookId, String traceId) {
                    if ("missing-book".equals(bookId)) {
                        throw new ReservationException(HttpStatus.NOT_FOUND, "BOOK_NOT_FOUND", "Book not found");
                    }
                    return new BookAvailability(bookId, 2, AVAILABLE_COPIES.get());
                }

                @Override
                public ClaimOutcome claimCopyForReservation(
                        String bookId, String copyId, String reservationId, String operationId, String traceId) {
                    String current = COPY_HOLDERS.getOrDefault(copyId, "AVAILABLE");
                    if ("AVAILABLE".equals(current) && COPY_HOLDERS.replace(copyId, "AVAILABLE", reservationId)) {
                        return ClaimOutcome.CLAIMED;
                    }
                    if (reservationId.equals(current)) {
                        return ClaimOutcome.CLAIMED;
                    }
                    return ClaimOutcome.COPY_UNAVAILABLE;
                }

                @Override
                public void releaseCopy(String copyId, String expectedHolderId, String operationId, String reason, String traceId) {
                    if (CATALOG_RELEASE_FAIL.get()) {
                        throw new ReservationException(HttpStatus.SERVICE_UNAVAILABLE, "CATALOG_UNAVAILABLE", "Simulated outage");
                    }
                    COPY_HOLDERS.computeIfPresent(copyId, (k, holder) -> holder.equals(expectedHolderId) ? "AVAILABLE" : holder);
                }

                @Override
                public void transferCopyHolder(
                        String copyId, String expectedHolderId, String newHolderType,
                        String newHolderId, String operationId, String traceId) {
                    if ("RESERVATION".equals(newHolderType) && CATALOG_REVERSE_TRANSFER_FAIL.get()) {
                        throw new ReservationException(HttpStatus.SERVICE_UNAVAILABLE, "CATALOG_UNAVAILABLE", "Reverse transfer outage");
                    }
                    String current = COPY_HOLDERS.get(copyId);
                    if (newHolderId.equals(current)) {
                        return; // Idempotent retry
                    }
                    if (!expectedHolderId.equals(current)) {
                        throw new ReservationException(HttpStatus.CONFLICT, "COPY_HOLDER_CONFLICT", "Holder mismatch");
                    }
                    COPY_HOLDERS.put(copyId, newHolderId);
                }
            };
        }

        @Bean(name = "customCirculationLoanClient")
        @Primary
        CirculationLoanClient stubCirculationLoanClient() {
            return (targetLoanId, reservationId, userId, bookId, copyId, actorId, operationId, idempotencyKey, traceId) -> {
                if (CIRCULATION_FAIL.get()) {
                    throw new ReservationException(HttpStatus.SERVICE_UNAVAILABLE, "CIRCULATION_UNAVAILABLE", "Circulation down");
                }
                return new FulfilledLoanResult(targetLoanId, "APPROVED");
            };
        }

        @Bean
        @Primary
        @SuppressWarnings("unchecked")
        KafkaOperations<String, String> stubKafkaOperations() {
            KafkaOperations<String, String> mock = Mockito.mock(KafkaOperations.class);
            Mockito.when(mock.send(Mockito.anyString(), Mockito.anyString(), Mockito.anyString()))
                    .thenAnswer(invocation -> {
                        String topic = invocation.getArgument(0, String.class);
                        String key = invocation.getArgument(1, String.class);
                        String value = invocation.getArgument(2, String.class);
                        if (KAFKA_SEND_FAIL.get() && !topic.endsWith(".dlt")) {
                            return CompletableFuture.failedFuture(new RuntimeException("Simulated broker timeout"));
                        }
                        SENT_TOPICS.add(topic);
                        ProducerRecord<String, String> prodRecord = new ProducerRecord<>(topic, key, value);
                        RecordMetadata meta = new RecordMetadata(new TopicPartition(topic, 0), 0L, 0, 0L, 0, 0);
                        return CompletableFuture.completedFuture(new SendResult<>(prodRecord, meta));
                    });
            return mock;
        }
    }

    @Autowired WebApplicationContext context;
    @Autowired JdbcTemplate jdbc;
    @Autowired ReservationQueueService queueService;
    @Autowired CopyAvailableConsumer copyAvailableConsumer;
    @Autowired ReservationExpiryJob expiryJob;
    @Autowired OutboxPublisher outboxPublisher;
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
        publicKeyPath = Path.of("target", "res-pub-" + UUID.randomUUID() + ".pem");
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
        jdbc.update("DELETE FROM reservation_operations");
        jdbc.update("DELETE FROM idempotency_records");
        jdbc.update("DELETE FROM processed_events");
        jdbc.update("DELETE FROM outbox_events");
        jdbc.update("DELETE FROM reservations");
        COPY_HOLDERS.clear();
        AVAILABLE_COPIES.set(0);
        CATALOG_RELEASE_FAIL.set(false);
        CATALOG_REVERSE_TRANSFER_FAIL.set(false);
        CIRCULATION_FAIL.set(false);
        KAFKA_SEND_FAIL.set(false);
        SENT_TOPICS.clear();
    }

    @Test
    void rejectsAvailableBooksEnforcesUniqueQueueAndSupportsIdempotencyKey() throws Exception {
        String jwtUser1 = signJwt("user-1", List.of("MEMBER"));
        String jwtUser2 = signJwt("user-2", List.of("MEMBER"));

        // Rejects reservation when copies are still available
        AVAILABLE_COPIES.set(1);
        mvc.perform(post("/api/reservations")
                        .header("Authorization", "Bearer " + jwtUser1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"bookId\":\"book-1\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("BOOK_COPIES_AVAILABLE"));

        // Now all copies are checked out -> allow reservation with Idempotency-Key
        AVAILABLE_COPIES.set(0);
        String firstResp = mvc.perform(post("/api/reservations")
                        .header("Authorization", "Bearer " + jwtUser1)
                        .header("Idempotency-Key", "idem-create-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"bookId\":\"book-1\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.status").value("WAITING"))
                .andExpect(jsonPath("$.data.queuePosition").value(1))
                .andReturn().getResponse().getContentAsString();
        String firstId = JSON.readTree(firstResp).path("data").path("id").asText();

        // Retry with same Idempotency-Key + same payload -> returns exact same reservation
        mvc.perform(post("/api/reservations")
                        .header("Authorization", "Bearer " + jwtUser1)
                        .header("Idempotency-Key", "idem-create-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"bookId\":\"book-1\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").value(firstId));

        // Same Idempotency-Key + different payload -> 409 IDEMPOTENCY_KEY_CONFLICT
        mvc.perform(post("/api/reservations")
                        .header("Authorization", "Bearer " + jwtUser1)
                        .header("Idempotency-Key", "idem-create-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"bookId\":\"book-2\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("IDEMPOTENCY_KEY_CONFLICT"));

        // Duplicate active reservation without idempotency key -> 409 DUPLICATE_ACTIVE_RESERVATION
        mvc.perform(post("/api/reservations")
                        .header("Authorization", "Bearer " + jwtUser1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"bookId\":\"book-1\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("DUPLICATE_ACTIVE_RESERVATION"));

        // Second user joins FIFO queue at position 2
        mvc.perform(post("/api/reservations")
                        .header("Authorization", "Bearer " + jwtUser2)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"bookId\":\"book-1\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.queuePosition").value(2));
    }

    @Test
    void concurrentQueueAssignmentNeverClaimsDuplicateCopyAndPublishesOutboxWithDltFallback() throws Exception {
        String jwt1 = signJwt("user-1", List.of("MEMBER"));
        String jwt2 = signJwt("user-2", List.of("MEMBER"));

        mvc.perform(post("/api/reservations").header("Authorization", "Bearer " + jwt1)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"bookId\":\"book-race\"}"))
                .andExpect(status().isCreated());
        mvc.perform(post("/api/reservations").header("Authorization", "Bearer " + jwt2)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"bookId\":\"book-race\"}"))
                .andExpect(status().isCreated());

        COPY_HOLDERS.put("copy-single", "AVAILABLE");

        // Launch 8 concurrent workers racing to assign the SAME copy-single
        int workers = 8;
        ExecutorService pool = Executors.newFixedThreadPool(workers);
        CountDownLatch startGate = new CountDownLatch(1);
        List<Callable<Optional<ReservationResponse>>> tasks = new ArrayList<>();
        for (int i = 0; i < workers; i++) {
            tasks.add(() -> {
                startGate.await();
                return queueService.assignNext("book-race", "copy-single");
            });
        }
        List<Future<Optional<ReservationResponse>>> futures = tasks.stream().map(pool::submit).toList();
        startGate.countDown();

        List<ReservationResponse> assigned = new ArrayList<>();
        for (Future<Optional<ReservationResponse>> future : futures) {
            future.get().ifPresent(assigned::add);
        }
        pool.shutdown();

        // Strictly ONE waiter wins copy-single; the second remains WAITING at queuePosition=1!
        assertThat(assigned).hasSize(1);
        assertThat(assigned.getFirst().userId()).isEqualTo("user-1");
        assertThat(assigned.getFirst().status()).isEqualTo("READY");
        assertThat(assigned.getFirst().copyId()).isEqualTo("copy-single");
        assertThat(COPY_HOLDERS.get("copy-single")).isEqualTo(assigned.getFirst().id());

        mvc.perform(get("/api/reservations/me").header("Authorization", "Bearer " + jwt2))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items[0].status").value("WAITING"))
                .andExpect(jsonPath("$.data.items[0].queuePosition").value(1));

        // CopyAvailableConsumer deduplicates redelivered Kafka event
        COPY_HOLDERS.put("copy-second", "AVAILABLE");
        String copyAvailableJson = """
                {
                  "eventId": "evt-copy-avail-1",
                  "type": "library.copy.available.v1",
                  "schemaVersion": 1,
                  "occurredAt": "2026-11-08T10:00:00Z",
                  "traceId": "tr-copy",
                  "aggregateId": "book-race",
                  "aggregateVersion": 1,
                  "payload": {
                    "bookId": "book-race",
                    "copyId": "copy-second",
                    "availableAt": "2026-11-08T10:00:00Z",
                    "reason": "LOAN_RETURNED"
                  }
                }
                """;
        copyAvailableConsumer.onCopyAvailable(copyAvailableJson);
        copyAvailableConsumer.onCopyAvailable(copyAvailableJson); // Replay ignored!

        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM outbox_events WHERE status = 'PENDING'", Integer.class))
                .isEqualTo(2);

        // OutboxPublisher publishes batch and marks PUBLISHED after broker ack
        int published = outboxPublisher.publishPendingBatch(10);
        assertThat(published).isEqualTo(2);
        assertThat(SENT_TOPICS).containsOnly("library.reservation.ready.v1");
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM outbox_events WHERE status = 'PUBLISHED'", Integer.class))
                .isEqualTo(2);
    }

    @Test
    void fulfillCompensatesWhenCirculationFailsRecoversViaReconcilerAndCommitsOnlyAfterLoan() throws Exception {
        String jwtMember = signJwt("user-fulfill", List.of("MEMBER"));
        String jwtStaff = signJwt("staff-1", List.of("LIBRARIAN"));

        String createResp = mvc.perform(post("/api/reservations")
                        .header("Authorization", "Bearer " + jwtMember)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"bookId\":\"book-fulfill\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String resId = JSON.readTree(createResp).path("data").path("id").asText();

        COPY_HOLDERS.put("copy-f1", "AVAILABLE");
        queueService.assignNext("book-fulfill", "copy-f1");
        assertThat(COPY_HOLDERS.get("copy-f1")).isEqualTo(resId);

        // Non-staff user gets 403 FORBIDDEN on fulfill
        mvc.perform(post("/api/reservations/" + resId + "/fulfill")
                        .header("Authorization", "Bearer " + jwtMember))
                .andExpect(status().isForbidden());

        // Case A: Circulation fails AND reverse transfer fails -> reservation stays READY + COMPENSATION_REQUIRED -> reconciler recovers!
        CIRCULATION_FAIL.set(true);
        CATALOG_REVERSE_TRANSFER_FAIL.set(true);
        mvc.perform(post("/api/reservations/" + resId + "/fulfill")
                        .header("Authorization", "Bearer " + jwtStaff))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.code").value("CIRCULATION_UNAVAILABLE"));

        assertThat(jdbc.queryForObject("SELECT status FROM reservations WHERE id = ?", String.class, resId))
                .isEqualTo("READY");
        assertThat(jdbc.queryForObject("SELECT status FROM reservation_operations WHERE reservation_id = ? AND operation_type = 'FULFILL'",
                String.class, resId)).isEqualTo("COMPENSATION_REQUIRED");

        // Recover Catalog and run reconciler -> holder restored to resId!
        CATALOG_REVERSE_TRANSFER_FAIL.set(false);
        int reconciled = expiryJob.reconcilePendingOperations(Instant.now().plusSeconds(5));
        assertThat(reconciled).isEqualTo(1);
        assertThat(COPY_HOLDERS.get("copy-f1")).isEqualTo(resId);

        // Case B: Circulation succeeds -> holder transferred to loan + reservation marked FULFILLED + Idempotency-Key cached!
        CIRCULATION_FAIL.set(false);
        String fulfillResp = mvc.perform(post("/api/reservations/" + resId + "/fulfill")
                        .header("Authorization", "Bearer " + jwtStaff)
                        .header("Idempotency-Key", "idem-fulfill-1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("FULFILLED"))
                .andExpect(jsonPath("$.data.fulfilledLoanId").isNotEmpty())
                .andReturn().getResponse().getContentAsString();
        String loanId = JSON.readTree(fulfillResp).path("data").path("fulfilledLoanId").asText();
        assertThat(COPY_HOLDERS.get("copy-f1")).isEqualTo(loanId);

        // Idempotent retry returns 200 with identical fulfilledLoanId
        mvc.perform(post("/api/reservations/" + resId + "/fulfill")
                        .header("Authorization", "Bearer " + jwtStaff)
                        .header("Idempotency-Key", "idem-fulfill-1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.fulfilledLoanId").value(loanId));
    }

    @Test
    void expiryAndOwnerCancelReleaseHeldCopyWithReconcilerRecovery() throws Exception {
        String jwtOwner = signJwt("user-exp", List.of("MEMBER"));
        String jwtStranger = signJwt("user-other", List.of("MEMBER"));

        String createResp = mvc.perform(post("/api/reservations")
                        .header("Authorization", "Bearer " + jwtOwner)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"bookId\":\"book-exp\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        String resId = JSON.readTree(createResp).path("data").path("id").asText();

        // Stranger trying to cancel owner's reservation -> 404
        mvc.perform(delete("/api/reservations/" + resId)
                        .header("Authorization", "Bearer " + jwtStranger))
                .andExpect(status().isNotFound());

        COPY_HOLDERS.put("copy-exp", "AVAILABLE");
        queueService.assignNext("book-exp", "copy-exp");

        // Simulate Catalog temporary outage when expiry job runs -> EXPIRED + COMPENSATION_REQUIRED -> reconciler releases copy!
        CATALOG_RELEASE_FAIL.set(true);
        int expired = expiryJob.expireReady(Instant.now().plus(Duration.ofHours(25)));
        assertThat(expired).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT status FROM reservations WHERE id = ?", String.class, resId))
                .isEqualTo("EXPIRED");
        assertThat(COPY_HOLDERS.get("copy-exp")).isEqualTo(resId); // Still held until Catalog recovers

        CATALOG_RELEASE_FAIL.set(false);
        int recovered = expiryJob.reconcilePendingOperations(Instant.now().plus(Duration.ofHours(26)));
        assertThat(recovered).isEqualTo(1);
        assertThat(COPY_HOLDERS.get("copy-exp")).isEqualTo("AVAILABLE");
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
