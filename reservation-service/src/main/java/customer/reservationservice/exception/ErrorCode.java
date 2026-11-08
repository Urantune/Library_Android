package customer.reservationservice.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;

@Getter
public enum ErrorCode {
    UNCATEGORIZED_EXCEPTION(9999, "Uncategorized Exception", HttpStatus.INTERNAL_SERVER_ERROR),
    UNAUTHORIZED(1001, "Unauthorized", HttpStatus.UNAUTHORIZED),
    BAD_REQUEST(1007, "Invalid request", HttpStatus.BAD_REQUEST),
    DUPLICATE_RESERVATION(1012, "An active reservation already exists for this book", HttpStatus.CONFLICT),
    RENEWAL_ALREADY_PENDING(1011, "A renewal request is already pending", HttpStatus.CONFLICT);

    ErrorCode(int code, String message, HttpStatusCode statusCode) {
        this.code = code;
        this.message = message;
        this.statusCode = statusCode;
    }

    private int code;
    private String message;
    private HttpStatusCode statusCode;
}