package customer.catalogservice.book.controller;

import java.time.Instant;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import java.util.LinkedHashMap;
import customer.catalogservice.book.service.BookWriteException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.dao.DataIntegrityViolationException;
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

    @ExceptionHandler(BookWriteException.class)
    public ResponseEntity<ErrorResponse> invalidBook(BookWriteException ex, HttpServletRequest request) {
        return ResponseEntity.status(ex.status()).body(new ErrorResponse(ex.status().value(), ex.code(),
            ex.getMessage(), null, ex.fieldErrors(), Instant.now(), trace(request)));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> validation(MethodArgumentNotValidException ex, HttpServletRequest request) {
        Map<String, String> fields = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error -> fields.putIfAbsent(error.getField(), error.getDefaultMessage()));
        return ResponseEntity.badRequest().body(new ErrorResponse(400, "INVALID_BOOK", "Invalid book input",
            null, fields, Instant.now(), trace(request)));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> invalidJson(HttpMessageNotReadableException ex, HttpServletRequest request) {
        return ResponseEntity.badRequest().body(new ErrorResponse(400, "INVALID_JSON", "Invalid JSON request",
            null, Map.of(), Instant.now(), trace(request)));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErrorResponse> conflict(DataIntegrityViolationException ex, HttpServletRequest request) {
        return ResponseEntity.status(409).body(new ErrorResponse(409, "BOOK_CONFLICT", "Book data conflicts with an existing record",
            null, Map.of(), Instant.now(), trace(request)));
    }

    private String trace(HttpServletRequest request) {
        return BookController.trace(request.getHeader("X-Correlation-Id"));
    }
}
