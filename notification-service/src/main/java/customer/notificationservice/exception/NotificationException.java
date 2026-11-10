package customer.notificationservice.exception;

import java.util.Map;
import org.springframework.http.HttpStatus;

public class NotificationException extends RuntimeException {
    private final HttpStatus status;
    private final String code;
    private final Map<String, String> fieldErrors;

    public NotificationException(HttpStatus status, String code, String message) {
        this(status, code, message, Map.of());
    }

    public NotificationException(HttpStatus status, String code, String message, Map<String, String> fieldErrors) {
        super(message);
        this.status = status;
        this.code = code;
        this.fieldErrors = fieldErrors == null ? Map.of() : Map.copyOf(fieldErrors);
    }

    public HttpStatus status() {
        return status;
    }

    public String code() {
        return code;
    }

    public Map<String, String> fieldErrors() {
        return fieldErrors;
    }
}
