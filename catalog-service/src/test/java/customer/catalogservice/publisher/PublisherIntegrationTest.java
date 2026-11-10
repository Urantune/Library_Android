package customer.catalogservice.publisher;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import catalogservice.CatalogServiceApplication;
import catalogservice.repository.PublisherRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
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
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.cache.CacheManager;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@SpringBootTest(
        classes = CatalogServiceApplication.class,
        properties = {
            "eureka.client.enabled=false",
            "spring.cloud.discovery.enabled=false",
            "app.seed.books=false"
        }
)
class PublisherIntegrationTest {
    private static final String DB = "jdbc:sqlite:target/publishers-" + UUID.randomUUID() + ".db";
    private static Path publicKeyPath;
    private static PrivateKey privateKey;
    private static final ObjectMapper JSON = new ObjectMapper();

    @Autowired WebApplicationContext context;
    @Autowired JdbcTemplate jdbc;
    @Autowired PublisherRepository publisherRepository;
    @Autowired CacheManager cacheManager;
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
        publicKeyPath = Path.of("target", "test-pub-" + UUID.randomUUID() + ".pem");
        Files.createDirectories(publicKeyPath.getParent());
        Files.writeString(publicKeyPath, pem, StandardCharsets.UTF_8);
    }

    @DynamicPropertySource
    static void dynamicProps(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", () -> DB);
        registry.add("security.jwt.public-key", () -> "file:" + publicKeyPath.toAbsolutePath());
    }

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).build();
        for (String table : new String[]{"book_authors", "book_categories", "book_copies", "books", "authors", "categories", "publishers"}) {
            jdbc.update("DELETE FROM " + table);
        }
        for (String cacheName : new String[]{"book-pages", "book-details"}) {
            var cache = cacheManager.getCache(cacheName);
            if (cache != null) {
                cache.clear();
            }
        }
    }

    @Test
    void createDetailSearchUpdateAndSoftDeleteFlowEvictsBookCaches() throws Exception {
        // Seed book cache entry first to verify post-commit invalidation
        jdbc.update("INSERT INTO books(id,isbn,title,status,created_at,updated_at) VALUES('b-1','9780132350884','Clean Code','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
        mvc.perform(get("/api/books")).andExpect(status().isOk());
        mvc.perform(get("/api/books/b-1")).andExpect(status().isOk());
        assertThat(cacheManager.getCache("book-pages").get("0:20:null:null:null:null")).isNotNull();
        assertThat(cacheManager.getCache("book-details").get("b-1")).isNotNull();

        // MSS-025: POST create publisher -> 201 Created + Location + traceId
        String createBody = """
                {
                  "name": "  NXB Trẻ  ",
                  "address": "161B Lý Chính Thắng, Q3, TP.HCM",
                  "email": "contact@nxbtre.com.vn",
                  "phone": "028-39316289",
                  "website": "https://www.nxbtre.com.vn"
                }
                """;
        String createResp = mvc.perform(post("/api/publishers")
                        .header("X-Trace-Id", "pub-create-trace")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createBody))
                .andExpect(status().isCreated())
                .andExpect(header().exists("Location"))
                .andExpect(jsonPath("$.status").value(201))
                .andExpect(jsonPath("$.traceId").value("pub-create-trace"))
                .andExpect(jsonPath("$.data.name").value("NXB Trẻ"))
                .andExpect(jsonPath("$.data.status").value("ACTIVE"))
                .andExpect(jsonPath("$.data.createdAt").isNotEmpty())
                .andReturn().getResponse().getContentAsString();

        String publisherId = JSON.readTree(createResp).path("data").path("id").asText();
        assertThat(UUID.fromString(publisherId)).isNotNull();
        assertThat(cacheManager.getCache("book-pages").get("0:20:null:null:null:null")).isNull();
        assertThat(cacheManager.getCache("book-details").get("b-1")).isNull();

        // Duplicate name (case-insensitive) -> 409 Conflict
        mvc.perform(post("/api/publishers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"nxb trẻ\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.status").value(409))
                .andExpect(jsonPath("$.code").value("DUPLICATE_PUBLISHER_NAME"))
                .andExpect(jsonPath("$.fieldErrors.name").exists());

        // Create second publisher for search & pagination testing
        mvc.perform(post("/api/publishers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"O'Reilly Media\",\"email\":\"info@oreilly.com\"}"))
                .andExpect(status().isCreated());

        // MSS-026: GET list with keyword filter & pagination
        mvc.perform(get("/api/publishers").param("q", "oreilly"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.items[0].name").value("O'Reilly Media"));

        // MSS-026: GET detail
        mvc.perform(get("/api/publishers/" + publisherId).header("X-Correlation-Id", "corr-detail"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.traceId").value("corr-detail"))
                .andExpect(jsonPath("$.data.email").value("contact@nxbtre.com.vn"));

        // MSS-027: PUT update publisher
        String updateBody = """
                {
                  "name": "NXB Trẻ TP.HCM",
                  "address": "Quận 3, TP.HCM",
                  "email": "bandoc@nxbtre.com.vn",
                  "phone": "028-39316289",
                  "website": "https://nxbtre.com.vn",
                  "status": "ACTIVE"
                }
                """;
        mvc.perform(put("/api/publishers/" + publisherId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("NXB Trẻ TP.HCM"))
                .andExpect(jsonPath("$.data.email").value("bandoc@nxbtre.com.vn"));

        // Link book to publisher to verify soft delete preserves FK integrity
        jdbc.update("UPDATE books SET publisher_id = ? WHERE id = 'b-1'", publisherId);

        // MSS-028: DELETE soft-deletes publisher idempotently -> 204 No Content
        mvc.perform(delete("/api/publishers/" + publisherId)).andExpect(status().isNoContent());
        mvc.perform(delete("/api/publishers/" + publisherId)).andExpect(status().isNoContent());

        // Default list excludes INACTIVE, while ?status=INACTIVE and GET /{id} still show historical record
        mvc.perform(get("/api/publishers"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1));
        mvc.perform(get("/api/publishers").param("status", "INACTIVE"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.items[0].id").value(publisherId));
        mvc.perform(get("/api/publishers/" + publisherId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("INACTIVE"));
        assertThat(jdbc.queryForObject("SELECT publisher_id FROM books WHERE id = 'b-1'", String.class))
                .isEqualTo(publisherId);
    }

    @Test
    void validationNotFoundPaginationAndJwtRbacErrorsReturnStructuredEnvelope() throws Exception {
        // 404 on unknown ID for GET / PUT / DELETE
        mvc.perform(get("/api/publishers/missing-id").header("X-Trace-Id", "t-404"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("PUBLISHER_NOT_FOUND"))
                .andExpect(jsonPath("$.traceId").value("t-404"));
        mvc.perform(put("/api/publishers/missing-id")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Valid\"}"))
                .andExpect(status().isNotFound());
        mvc.perform(delete("/api/publishers/missing-id"))
                .andExpect(status().isNotFound());

        // 400 on invalid input / bad email / invalid status / bad pagination
        mvc.perform(post("/api/publishers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"   \",\"email\":\"not-an-email\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_PUBLISHER"))
                .andExpect(jsonPath("$.fieldErrors.name").exists())
                .andExpect(jsonPath("$.fieldErrors.email").exists());

        mvc.perform(post("/api/publishers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Valid\",\"status\":\"BOGUS\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.status").exists());

        for (String[] param : new String[][]{{"page", "-1"}, {"size", "0"}, {"size", "101"}, {"status", "WRONG"}}) {
            mvc.perform(get("/api/publishers").param(param[0], param[1]))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.status").value(400));
        }

        String memberJwt = signJwt("user-member-1", List.of("USER"), Instant.now().plusSeconds(300));
        String staffJwt = signJwt("user-staff-1", List.of("ADMIN"), Instant.now().plusSeconds(300));
        String expiredJwt = signJwt("user-staff-1", List.of("ADMIN"), Instant.now().minusSeconds(60));

        mvc.perform(get("/api/publishers").header("Authorization", "Bearer " + expiredJwt))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"));

        mvc.perform(get("/api/publishers").header("Authorization", "Bearer " + memberJwt))
                .andExpect(status().isOk());

        mvc.perform(post("/api/publishers")
                        .header("Authorization", "Bearer " + memberJwt)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Forbidden Press\"}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("FORBIDDEN"));

        mvc.perform(post("/api/publishers")
                        .header("Authorization", "Bearer " + staffJwt)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Staff Allowed Press\"}"))
                .andExpect(status().isCreated());
    }

    private static String signJwt(String sub, List<String> roles, Instant exp) throws Exception {
        String headerJson = JSON.writeValueAsString(Map.of("alg", "RS256", "typ", "JWT"));
        String payloadJson = JSON.writeValueAsString(Map.of(
                "iss", "library-identity",
                "aud", List.of("library-api"),
                "sub", sub,
                "roles", roles,
                "exp", exp.getEpochSecond()
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
