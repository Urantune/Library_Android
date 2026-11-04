package customer.circulationservice.dto.response;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@FieldDefaults(level = AccessLevel.PRIVATE)
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class LoanItemResponseDTO {
     String id;
     String bookId;
     String copyId;
     String itemStatus; // REQUESTED, BORROWED, RETURNED, LOST
     String returnedAt;
     String conditionOnReturn;
     Double fineAmount;
}