package customer.notificationservice.exception;

import customer.notificationservice.controller.NotificationController;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

@RestControllerAdvice
public class NotificationExceptionHandler {

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

    @ExceptionHandler(NotificationException.class)
    public ResponseEntity<ErrorEnvelope> handleNotificationException(NotificationException ex, HttpServletRequest request) {
        return ResponseEntity.status(ex.status()).body(new ErrorEnvelope(
                ex.status().value(),
                ex.code(),
                ex.getMessage(),
                null,
                ex.fieldErrors(),
                Instant.now(),
                NotificationController.resolveTraceId(request)
        ));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorEnvelope> handleValidation(MethodArgumentNotValidException ex, HttpServletRequest request) {
        Map<String, String> fields = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors()
                .forEach(err -> fields.putIfAbsent(err.getField(), err.getDefaultMessage()));
        return ResponseEntity.badRequest().body(new ErrorEnvelope(
                400,
                "VALIDATION_ERROR",
                "Invalid notification request",
                null,
                fields,
                Instant.now(),
                NotificationController.resolveTraceId(request)
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
                NotificationController.resolveTraceId(request)
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
                NotificationController.resolveTraceId(request)
        ));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErrorEnvelope> handleDataIntegrity(DataIntegrityViolationException ex, HttpServletRequest request) {
        return ResponseEntity.status(409).body(new ErrorEnvelope(
                409,
                "CONFLICT",
                "Data integrity conflict",
                null,
                Map.of(),
                Instant.now(),
                NotificationController.resolveTraceId(request)
        ));
    }
}
