package customer.identityservice.auth.dto;

import java.time.Instant;
import java.util.Map;

public record ApiResponse<T>(int status, String code, String message, T data,
                             Map<String,String> fieldErrors, Instant timestamp, String traceId) {
    public static <T> ApiResponse<T> success(int status, T data, String traceId) {
        return new ApiResponse<>(status, "OK", "Thành công", data, Map.of(), Instant.now(), traceId);
    }
}
