package customer.circulationservice.dto.request;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@FieldDefaults(level = AccessLevel.PRIVATE)
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class LoanItemRequestDTO {
     String bookId;
     String copyId;
}