package customer.catalogservice.book.controller;

import java.time.Instant;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.server.ResponseStatusException;

@RestControllerAdvice(assignableTypes = BookController.class)
public class BookExceptionHandler {
    public record ErrorResponse(int status, String code, String message, Object data,
                                Map<String, String> fieldErrors, Instant timestamp, String traceId) {}

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ErrorResponse> handle(ResponseStatusException ex,
        HttpServletRequest request) {
        int status = ex.getStatusCode().value();
        return ResponseEntity.status(status).body(new ErrorResponse(status,
            status == 404 ? "BOOK_NOT_FOUND" : "INVALID_PAGINATION", ex.getReason(), null,
            Map.of(), Instant.now(), BookController.trace(request.getHeader("X-Correlation-Id"))));
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorResponse> invalidParameter(MethodArgumentTypeMismatchException ex,
        HttpServletRequest request) {
        return ResponseEntity.badRequest().body(new ErrorResponse(400, "INVALID_PARAMETER",
            "Invalid parameter: " + ex.getName(), null, Map.of(), Instant.now(), BookController.trace(request.getHeader("X-Correlation-Id"))));
    }
}
