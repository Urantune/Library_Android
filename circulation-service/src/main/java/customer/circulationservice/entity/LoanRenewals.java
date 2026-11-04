package customer.circulationservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "loan_renewals")
@FieldDefaults(level = AccessLevel.PRIVATE)
public class LoanRenewals {
    @Id
    @Column(name = "id", nullable = false)
     String id;

    @Column(name = "loan_id", nullable = false)
     String loanId;

    @Column(name = "requested_by", nullable = false)
     String requestedBy;

    @Column(name = "requested_at", nullable = false)
     String requestedAt;

    @Column(name = "previous_due_at", nullable = false)
     String previousDueAt;

    @Column(name = "new_due_at")
     String newDueAt;

    @Column(name = "status", nullable = false)
     String status; // ('REQUESTED', 'APPROVED', 'REJECTED')

    @Column(name = "approved_by")
     String approvedBy;

    @Column(name = "decision_at")
     String decisionAt;

    @Column(name = "reason")
     String reason;
}
