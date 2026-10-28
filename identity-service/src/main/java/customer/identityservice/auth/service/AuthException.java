package customer.identityservice.auth.service;

import java.util.Map;

public class AuthException extends RuntimeException {
    public final int status;
    public final String code;
    public final Map<String,String> fields;
    public final long retryAfter;

    public AuthException(int status, String code, String message) {
        this(status, code, message, Map.of(), 0);
    }

    public AuthException(int status, String code, String message, Map<String,String> fields, long retryAfter) {
        super(message);
        this.status = status;
        this.code = code;
        this.fields = fields;
        this.retryAfter = retryAfter;
    }
}
