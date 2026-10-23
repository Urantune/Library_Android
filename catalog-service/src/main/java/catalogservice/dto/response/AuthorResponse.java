package catalogservice.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AuthorResponse {
    String name;
    String bio;
    LocalDate birthDate;
    String country;
    String status;
    LocalDateTime created_at;
    LocalDateTime updated_at;
}
