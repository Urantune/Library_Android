package customer.catalogservice.book.service;

import java.util.Map;
import org.springframework.http.HttpStatus;

public class BookWriteException extends RuntimeException {
    private final HttpStatus status;
    private final String code;
    private final Map<String, String> fieldErrors;

    public BookWriteException(HttpStatus status, String code, String field, String message) {
        super(message);
        this.status = status;
        this.code = code;
        this.fieldErrors = Map.of(field, message);
    }

    public HttpStatus status() { return status; }
    public String code() { return code; }
    public Map<String, String> fieldErrors() { return fieldErrors; }
}
