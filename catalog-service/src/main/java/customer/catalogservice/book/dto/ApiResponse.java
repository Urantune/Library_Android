package customer.catalogservice.book.dto;

import java.time.Instant;

public record ApiResponse<T>(int status, String message, T data, Instant timestamp, String traceId) {
    public static <T> ApiResponse<T> ok(T data, String traceId) {
        return new ApiResponse<>(200, "OK", data, Instant.now(), traceId);
    }
}
