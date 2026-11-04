package customer.apigateway;

import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class GatewayRoutingTests {
    private static final HttpServer DOWNSTREAM = startDownstream();

    @LocalServerPort
    private int port;

    private final HttpClient client = HttpClient.newHttpClient();

    private static HttpServer startDownstream() {
        try {
            HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
            server.createContext("/", exchange -> {
                String body = exchange.getRequestURI() + "|"
                        + exchange.getRequestHeaders().getFirst(TraceIdFilter.HEADER);
                byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
                exchange.sendResponseHeaders(200, bytes.length);
                try (var output = exchange.getResponseBody()) {
                    output.write(bytes);
                }
            });
            server.start();
            return server;
        } catch (IOException exception) {
            throw new IllegalStateException(exception);
        }
    }

    @DynamicPropertySource
    static void routes(DynamicPropertyRegistry registry) {
        for (String service : new String[]{"IDENTITY", "CATALOG", "CIRCULATION", "RESERVATION", "NOTIFICATION"}) {
            registry.add(service + "_SERVICE_URI",
                    () -> "http://127.0.0.1:" + DOWNSTREAM.getAddress().getPort());
        }
    }

    @AfterAll
    static void stopDownstream() {
        DOWNSTREAM.stop(0);
    }

    private HttpResponse<String> get(String path, String traceId) throws Exception {
        HttpRequest.Builder request = HttpRequest.newBuilder(URI.create("http://localhost:" + port + path));
        if (traceId != null) {
            request.header(TraceIdFilter.HEADER, traceId);
        }
        return client.send(request.GET().build(), HttpResponse.BodyHandlers.ofString());
    }

    @Test
    void routesAllFiveServicesAndPreservesQueryAndTraceId() throws Exception {
        for (String service : new String[]{"identity", "catalog", "circulation", "reservation", "notification"}) {
            HttpResponse<String> response = get("/api/" + service + "/probe?page=2", "trace-123");
            assertEquals(200, response.statusCode());
            assertEquals("/probe?page=2|trace-123", response.body());
            assertEquals("trace-123", response.headers().firstValue(TraceIdFilter.HEADER).orElseThrow());
        }
    }

    @Test
    void keepsLegacyAliasAndReplacesInvalidTraceId() throws Exception {
        HttpResponse<String> response = get("/catalog/probe", "invalid trace");
        assertEquals(200, response.statusCode());
        String traceId = response.headers().firstValue(TraceIdFilter.HEADER).orElseThrow();
        assertNotNull(UUID.fromString(traceId));
        assertEquals("/probe|" + traceId, response.body());
    }

    @Test
    void exposesReadinessMetricsAndRejectsUnknownRoute() throws Exception {
        assertEquals(200, get("/actuator/health/readiness", null).statusCode());
        assertEquals(200, get("/actuator/metrics", null).statusCode());
        assertEquals(200, get("/actuator/prometheus", null).statusCode());
        assertEquals(404, get("/api/unknown/probe", null).statusCode());
    }
}
