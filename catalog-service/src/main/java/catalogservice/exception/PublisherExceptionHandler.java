package catalogservice.exception;

import catalogservice.controller.PublisherController;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.server.ResponseStatusException;

@RestControllerAdvice(assignableTypes = PublisherController.class)
@Order(Ordered.HIGHEST_PRECEDENCE)
public class PublisherExceptionHandler {

    public record ErrorEnvelope(
            int status,
            String code,
            String message,
            Object data,
            Map<String, String> fieldErrors,
            Instant timestamp,
            String traceId
    ) {
    }

    @ExceptionHandler(PublisherException.class)
    public ResponseEntity<ErrorEnvelope> handlePublisherException(PublisherException ex, HttpServletRequest request) {
        return ResponseEntity.status(ex.status()).body(new ErrorEnvelope(
                ex.status().value(),
                ex.code(),
                ex.getMessage(),
                null,
                ex.fieldErrors(),
                Instant.now(),
                PublisherController.resolveTraceId(request)
        ));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorEnvelope> handleValidation(MethodArgumentNotValidException ex, HttpServletRequest request) {
        Map<String, String> fields = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors()
                .forEach(err -> fields.putIfAbsent(err.getField(), err.getDefaultMessage()));
        return ResponseEntity.badRequest().body(new ErrorEnvelope(
                400,
                "INVALID_PUBLISHER",
                "Invalid publisher input",
                null,
                fields,
                Instant.now(),
                PublisherController.resolveTraceId(request)
        ));
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorEnvelope> handleTypeMismatch(MethodArgumentTypeMismatchException ex, HttpServletRequest request) {
        return ResponseEntity.badRequest().body(new ErrorEnvelope(
                400,
                "INVALID_PARAMETER",
                "Invalid parameter: " + ex.getName(),
                null,
                Map.of(ex.getName(), "Invalid parameter value"),
                Instant.now(),
                PublisherController.resolveTraceId(request)
        ));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorEnvelope> handleInvalidJson(HttpMessageNotReadableException ex, HttpServletRequest request) {
        return ResponseEntity.badRequest().body(new ErrorEnvelope(
                400,
                "INVALID_JSON",
                "Malformed JSON request body",
                null,
                Map.of(),
                Instant.now(),
                PublisherController.resolveTraceId(request)
        ));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErrorEnvelope> handleDataIntegrity(DataIntegrityViolationException ex, HttpServletRequest request) {
        return ResponseEntity.status(409).body(new ErrorEnvelope(
                409,
                "PUBLISHER_CONFLICT",
                "Publisher data conflicts with an existing record",
                null,
                Map.of(),
                Instant.now(),
                PublisherController.resolveTraceId(request)
        ));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ErrorEnvelope> handleResponseStatus(ResponseStatusException ex, HttpServletRequest request) {
        int status = ex.getStatusCode().value();
        String code = status == 404 ? "PUBLISHER_NOT_FOUND"
                : status == 409 ? "PUBLISHER_CONFLICT" : "INVALID_PARAMETER";
        return ResponseEntity.status(ex.getStatusCode()).body(new ErrorEnvelope(
                status,
                code,
                ex.getReason() == null ? "Publisher request failed" : ex.getReason(),
                null,
                Map.of(),
                Instant.now(),
                PublisherController.resolveTraceId(request)
        ));
    }
}
