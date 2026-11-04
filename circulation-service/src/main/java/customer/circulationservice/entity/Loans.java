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
@Table(name = "loans")
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Loans {
    @Id
    @Column(name = "id", nullable = false)
    private String id;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @Column(name = "status", nullable = false)
    private String status; // ('REQUESTED', 'APPROVED', 'BORROWED', 'RETURNED', 'REJECTED', ...)

    @Column(name = "requested_at", nullable = false)
    private String requestedAt; // Có thể đổi sang kiểu LocalDateTime nếu cần

    @Column(name = "approved_at")
    private String approvedAt;

    @Column(name = "borrowed_at")
    private String borrowedAt;

    @Column(name = "due_at")
    private String dueAt;

    @Column(name = "returned_at")
    private String returnedAt;

    @Column(name = "processed_by")
    private String processedBy;

    @Column(name = "rejection_reason")
    private String rejectionReason;

    @Column(name = "renew_count", nullable = false)
    private Integer renewCount = 0; // DEFAULT 0

    @Column(name = "created_at", nullable = false)
    private String createdAt;

    @Column(name = "updated_at", nullable = false)
    private String updatedAt;
}
