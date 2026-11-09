package customer.reservationservice.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import customer.reservationservice.dto.ReservationDtos.BookAvailability;
import customer.reservationservice.dto.ReservationDtos.ClaimOutcome;
import customer.reservationservice.exception.ReservationException;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

public class HttpCatalogInventoryClient implements CatalogInventoryClient {
    private final RestClient restClient;
    private final ObjectMapper mapper;
    private final String internalToken;

    public HttpCatalogInventoryClient(
            ObjectMapper mapper,
            @Value("${app.clients.catalog.base-url:http://localhost:8082}") String baseUrl,
            @Value("${app.clients.internal-token:dev-internal-service-token}") String internalToken
    ) {
        this.mapper = mapper;
        this.internalToken = internalToken;
        this.restClient = RestClient.builder().baseUrl(baseUrl).build();
    }

    @Override
    public BookAvailability getAvailability(String bookId, String traceId) {
        try {
            String raw = restClient.get()
                    .uri("/api/books/{bookId}", bookId)
                    .header("X-Internal-Token", internalToken)
                    .header("X-Trace-Id", traceId == null ? "" : traceId)
                    .retrieve()
                    .body(String.class);
            JsonNode root = mapper.readTree(raw);
            JsonNode data = root.has("data") ? root.get("data") : root;
            int totalCopies = data.path("totalCopies").asInt(0);
            long availableCopies = data.path("availableCopies").asLong(0L);
            return new BookAvailability(bookId, totalCopies, availableCopies);
        } catch (HttpClientErrorException.NotFound ex) {
            throw new ReservationException(HttpStatus.NOT_FOUND, "BOOK_NOT_FOUND", "Book not found: " + bookId);
        } catch (Exception ex) {
            throw new ReservationException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "CATALOG_UNAVAILABLE",
                    "Catalog service unavailable when checking book availability"
            );
        }
    }

    @Override
    public ClaimOutcome claimCopyForReservation(
            String bookId,
            String copyId,
            String reservationId,
            String operationId,
            String traceId
    ) {
        try {
            restClient.post()
                    .uri("/internal/copies/{copyId}/claim", copyId)
                    .header("X-Internal-Token", internalToken)
                    .header("X-Trace-Id", traceId == null ? "" : traceId)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of(
                            "bookId", bookId,
                            "holderType", "RESERVATION",
                            "holderId", reservationId,
                            "operationId", operationId
                    ))
                    .retrieve()
                    .toBodilessEntity();
            return ClaimOutcome.CLAIMED;
        } catch (HttpClientErrorException.Conflict | HttpClientErrorException.NotFound ex) {
            return ClaimOutcome.COPY_UNAVAILABLE;
        } catch (RestClientException ex) {
            throw new ReservationException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "CATALOG_UNAVAILABLE",
                    "Catalog service unavailable when claiming copy " + copyId
            );
        }
    }

    @Override
    public void releaseCopy(String copyId, String expectedHolderId, String operationId, String reason, String traceId) {
        try {
            restClient.post()
                    .uri("/internal/copies/{copyId}/release", copyId)
                    .header("X-Internal-Token", internalToken)
                    .header("X-Trace-Id", traceId == null ? "" : traceId)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of(
                            "expectedHolderId", expectedHolderId,
                            "operationId", operationId,
                            "reason", reason
                    ))
                    .retrieve()
                    .toBodilessEntity();
        } catch (RestClientException ex) {
            throw new ReservationException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "CATALOG_UNAVAILABLE",
                    "Catalog service unavailable when releasing copy " + copyId
            );
        }
    }

    @Override
    public void transferCopyHolder(
            String copyId,
            String expectedHolderId,
            String newHolderType,
            String newHolderId,
            String operationId,
            String traceId
    ) {
        try {
            restClient.post()
                    .uri("/internal/copies/{copyId}/transfer-holder", copyId)
                    .header("X-Internal-Token", internalToken)
                    .header("X-Trace-Id", traceId == null ? "" : traceId)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of(
                            "expectedHolderId", expectedHolderId,
                            "newHolderType", newHolderType,
                            "newHolderId", newHolderId,
                            "operationId", operationId
                    ))
                    .retrieve()
                    .toBodilessEntity();
        } catch (HttpClientErrorException.Conflict ex) {
            throw new ReservationException(
                    HttpStatus.CONFLICT,
                    "COPY_HOLDER_CONFLICT",
                    "Held copy holder state no longer matches reservation"
            );
        } catch (RestClientException ex) {
            throw new ReservationException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "CATALOG_UNAVAILABLE",
                    "Catalog service unavailable when transferring copy holder"
            );
        }
    }
}
