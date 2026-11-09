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
@Table(name = "loan_items")
@FieldDefaults(level = AccessLevel.PRIVATE)
public class LoanItems {
    @Id
    @Column(name = "id", nullable = false)
    String id;

    @Column(name = "loan_id", nullable = false)
    String loanId;

    @Column(name = "book_id", nullable = false)
    String bookId;

    @Column(name = "copy_id")
    String copyId;

    @Column(name = "item_status", nullable = false)
    String itemStatus; //[cite: 1] ('REQUESTED', 'BORROWED', 'RETURNED', 'LOST')

    @Column(name = "returned_at")
    String returnedAt;

    @Column(name = "condition_on_return")
    String conditionOnReturn; //[cite: 1]

    @Column(name = "fine_amount", nullable = false)
    Double fineAmount = 0.0; //[cite: 1] (DEFAULT 0)

    @Column(name = "return_operation_id")
    String returnOperationId;
}
