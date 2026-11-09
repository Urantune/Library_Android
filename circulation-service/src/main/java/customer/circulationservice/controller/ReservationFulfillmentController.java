package customer.circulationservice.controller;

import customer.circulationservice.dto.request.ReservationFulfillmentRequest;
import customer.circulationservice.dto.response.ReservationFulfillmentResponse;
import customer.circulationservice.service.impl.ReservationFulfillmentService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/internal/loans")
public class ReservationFulfillmentController {
    private final ReservationFulfillmentService fulfillment;
    private final byte[] internalToken;

    public ReservationFulfillmentController(
            ReservationFulfillmentService fulfillment,
            @Value("${app.clients.internal-token:dev-internal-service-token}") String internalToken
    ) {
        if (internalToken == null || internalToken.isBlank()) {
            throw new IllegalArgumentException("INTERNAL_SERVICE_TOKEN must not be blank");
        }
        this.fulfillment = fulfillment;
        this.internalToken = internalToken.getBytes(StandardCharsets.UTF_8);
    }

    @PostMapping(value = "/fulfill-reservation", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Envelope<ReservationFulfillmentResponse>> fulfill(
            @Valid @RequestBody ReservationFulfillmentRequest request,
            @RequestHeader("X-Internal-Token") String token,
            @RequestHeader("Idempotency-Key") String idempotencyKey,
            HttpServletRequest servletRequest
    ) {
        if (token == null || token.isBlank()
                || !MessageDigest.isEqual(internalToken, token.getBytes(StandardCharsets.UTF_8))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid internal service token");
        }
        ReservationFulfillmentResponse data = fulfillment.fulfill(request, idempotencyKey);
        return ResponseEntity.ok(new Envelope<>(data, Instant.now().toString(), trace(servletRequest)));
    }

    private static String trace(HttpServletRequest request) {
        String trace = request.getHeader("X-Trace-Id");
        if (trace == null || trace.isBlank()) trace = request.getHeader("X-Correlation-Id");
        return trace == null || trace.isBlank() ? java.util.UUID.randomUUID().toString() : trace;
    }

    public record Envelope<T>(T data, String timestamp, String traceId) {
    }
}
