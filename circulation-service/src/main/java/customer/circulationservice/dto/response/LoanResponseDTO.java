package customer.circulationservice.dto.response;


import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Getter
@Setter
@FieldDefaults(level = AccessLevel.PRIVATE)
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class LoanResponseDTO {
     String id;
     String userId;
     String status; // REQUESTED, APPROVED, BORROWED, RETURNED, REJECTED
     String requestedAt;
     String approvedAt;
     String borrowedAt;
     String dueAt;
     String returnedAt;
     String rejectionReason;
     Integer renewCount;
     List<LoanItemResponseDTO> items;
}