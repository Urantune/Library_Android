package customer.circulationservice.dto.response;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@FieldDefaults(level = AccessLevel.PRIVATE)
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class LoanRenewalResponseDTO {
    String id;
    String loanId;
    String requestedBy;
    String requestedAt;
    String previousDueAt;
    String newDueAt;
    String status;
    String approvedBy;
    String decisionAt;
    String reason;
}
