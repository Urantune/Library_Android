package customer.circulationservice.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;

@Getter
public enum ErrorCode {
    UNCATEGORIZED_EXCEPTION(9999, "Uncategorized Exception", HttpStatus.INTERNAL_SERVER_ERROR),
    UNAUTHORIZED(1001, "Unauthorized", HttpStatus.UNAUTHORIZED),
    INVALID_KEY(1002, "Invalid Key", HttpStatus.UNAUTHORIZED),
    USER_NOT_FOUND(1003, "User not found", HttpStatus.NOT_FOUND),
    USER_NOT_ACTIVE(1004, "User is not active", HttpStatus.CONFLICT),
    DUPLICATE_LOAN_ITEM(1005, "A book or copy appears more than once in the request", HttpStatus.BAD_REQUEST),
    IDENTITY_SERVICE_UNAVAILABLE(1006, "Identity service is unavailable", HttpStatus.SERVICE_UNAVAILABLE),
    BAD_REQUEST(1007, "Invalid request", HttpStatus.BAD_REQUEST),
    LOAN_NOT_FOUND(1008, "Loan not found", HttpStatus.NOT_FOUND),
    LOAN_ACCESS_DENIED(1009, "Loan does not belong to the current user", HttpStatus.FORBIDDEN),
    LOAN_NOT_RENEWABLE(1010, "Loan is not eligible for renewal", HttpStatus.CONFLICT),
    RENEWAL_ALREADY_PENDING(1011, "A renewal request is already pending", HttpStatus.CONFLICT),
    ADMIN_ACCESS_DENIED(1012, "Administrator role is required", HttpStatus.FORBIDDEN),
    LOAN_NOT_APPROVABLE(1013, "Loan is not in a state that can be approved", HttpStatus.CONFLICT),
    LOAN_NOT_REJECTABLE(1014, "Loan is not in a state that can be rejected", HttpStatus.CONFLICT);

    ErrorCode(int code, String message, HttpStatusCode statusCode) {
        this.code = code;
        this.message = message;
        this.statusCode = statusCode;
    }

    private int code;
    private String message;
    private HttpStatusCode statusCode;
}