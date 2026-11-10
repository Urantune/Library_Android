package customer.reservationservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "reservation_operations")
public class ReservationOperationEntity {
    @Id
    @Column(columnDefinition = "TEXT", nullable = false)
    private String id;

    @Column(name = "reservation_id", columnDefinition = "TEXT", nullable = false)
    private String reservationId;

    @Column(name = "operation_type", columnDefinition = "TEXT", nullable = false)
    private String operationType;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String status;

    @Column(name = "book_id", columnDefinition = "TEXT", nullable = false)
    private String bookId;

    @Column(name = "copy_id", columnDefinition = "TEXT")
    private String copyId;

    @Column(name = "target_loan_id", columnDefinition = "TEXT")
    private String targetLoanId;

    @Column(name = "actor_id", columnDefinition = "TEXT")
    private String actorId;

    @Column(name = "idempotency_key", columnDefinition = "TEXT")
    private String idempotencyKey;

    @Column(name = "request_hash", columnDefinition = "TEXT")
    private String requestHash;

    @Column(name = "attempt_count", nullable = false)
    private int attemptCount;

    @Column(name = "next_retry_at", columnDefinition = "TEXT")
    private String nextRetryAt;

    @Column(name = "last_error", columnDefinition = "TEXT")
    private String lastError;

    @Column(name = "created_at", columnDefinition = "TEXT", nullable = false)
    private String createdAt;

    @Column(name = "updated_at", columnDefinition = "TEXT", nullable = false)
    private String updatedAt;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getReservationId() { return reservationId; }
    public void setReservationId(String reservationId) { this.reservationId = reservationId; }
    public String getOperationType() { return operationType; }
    public void setOperationType(String operationType) { this.operationType = operationType; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getBookId() { return bookId; }
    public void setBookId(String bookId) { this.bookId = bookId; }
    public String getCopyId() { return copyId; }
    public void setCopyId(String copyId) { this.copyId = copyId; }
    public String getTargetLoanId() { return targetLoanId; }
    public void setTargetLoanId(String targetLoanId) { this.targetLoanId = targetLoanId; }
    public String getActorId() { return actorId; }
    public void setActorId(String actorId) { this.actorId = actorId; }
    public String getIdempotencyKey() { return idempotencyKey; }
    public void setIdempotencyKey(String idempotencyKey) { this.idempotencyKey = idempotencyKey; }
    public String getRequestHash() { return requestHash; }
    public void setRequestHash(String requestHash) { this.requestHash = requestHash; }
    public int getAttemptCount() { return attemptCount; }
    public void setAttemptCount(int attemptCount) { this.attemptCount = attemptCount; }
    public String getNextRetryAt() { return nextRetryAt; }
    public void setNextRetryAt(String nextRetryAt) { this.nextRetryAt = nextRetryAt; }
    public String getLastError() { return lastError; }
    public void setLastError(String lastError) { this.lastError = lastError; }
    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
    public String getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(String updatedAt) { this.updatedAt = updatedAt; }
}
