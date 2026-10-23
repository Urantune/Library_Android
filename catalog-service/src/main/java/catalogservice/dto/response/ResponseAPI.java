package catalogservice.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class ResponseAPI<T> {
    @Builder.Default
    int code = 1000;
    String message;
    String timestamp;
    T result;
}
