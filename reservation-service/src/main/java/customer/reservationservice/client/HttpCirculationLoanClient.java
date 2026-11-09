package customer.reservationservice.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import customer.reservationservice.dto.ReservationDtos.FulfilledLoanResult;
import customer.reservationservice.exception.ReservationException;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;

public class HttpCirculationLoanClient implements CirculationLoanClient {
    private final RestClient restClient;
    private final ObjectMapper mapper;
    private final String internalToken;

    public HttpCirculationLoanClient(
            ObjectMapper mapper,
            @Value("${app.clients.circulation.base-url:http://localhost:8083}") String baseUrl,
            @Value("${app.clients.internal-token:dev-internal-service-token}") String internalToken
    ) {
        this.mapper = mapper;
        this.internalToken = internalToken;
        this.restClient = RestClient.builder().baseUrl(baseUrl).build();
    }

    @Override
    public FulfilledLoanResult fulfillReservationIntoLoan(
            String targetLoanId,
            String reservationId,
            String userId,
            String bookId,
            String copyId,
            String actorId,
            String operationId,
            String idempotencyKey,
            String traceId
    ) {
        try {
            String effectiveKey = (idempotencyKey == null || idempotencyKey.isBlank()) ? operationId : idempotencyKey;
            String raw = restClient.post()
                    .uri("/internal/loans/fulfill-reservation")
                    .header("X-Internal-Token", internalToken)
                    .header("Idempotency-Key", effectiveKey)
                    .header("X-Trace-Id", traceId == null ? "" : traceId)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of(
                            "loanId", targetLoanId,
                            "reservationId", reservationId,
                            "userId", userId,
                            "bookId", bookId,
                            "copyId", copyId,
                            "processedBy", actorId,
                            "operationId", operationId
                    ))
                    .retrieve()
                    .body(String.class);
            if (raw == null || raw.isBlank()) {
                return new FulfilledLoanResult(targetLoanId, "APPROVED");
            }
            JsonNode root = mapper.readTree(raw);
            JsonNode data = root.has("data") ? root.get("data") : (root.has("result") ? root.get("result") : root);
            String returnedLoanId = data.path("loanId").asText(data.path("id").asText(targetLoanId));
            String loanStatus = data.path("status").asText("APPROVED");
            return new FulfilledLoanResult(returnedLoanId, loanStatus);
        } catch (HttpClientErrorException.Conflict ex) {
            throw new ReservationException(
                    HttpStatus.CONFLICT,
                    "LOAN_FULFILL_CONFLICT",
                    "Circulation rejected loan fulfillment due to conflict"
            );
        } catch (Exception ex) {
            throw new ReservationException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "CIRCULATION_UNAVAILABLE",
                    "Circulation service failed to commit loan for reservation " + reservationId
            );
        }
    }
}
