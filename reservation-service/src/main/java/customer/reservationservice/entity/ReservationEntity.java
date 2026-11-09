package customer.reservationservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "reservations")
public class ReservationEntity {
    @Id
    @Column(columnDefinition = "TEXT", nullable = false)
    private String id;

    @Column(name = "user_id", columnDefinition = "TEXT", nullable = false)
    private String userId;

    @Column(name = "book_id", columnDefinition = "TEXT", nullable = false)
    private String bookId;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String status;

    @Column(name = "queue_no", nullable = false)
    private int queueNo;

    @Column(name = "held_copy_id", columnDefinition = "TEXT")
    private String heldCopyId;

    @Column(name = "created_at", columnDefinition = "TEXT", nullable = false)
    private String createdAt;

    @Column(name = "ready_at", columnDefinition = "TEXT")
    private String readyAt;

    @Column(name = "expires_at", columnDefinition = "TEXT")
    private String expiresAt;

    @Column(name = "fulfilled_at", columnDefinition = "TEXT")
    private String fulfilledAt;

    @Column(name = "cancelled_at", columnDefinition = "TEXT")
    private String cancelledAt;

    @Column(name = "expired_at", columnDefinition = "TEXT")
    private String expiredAt;

    @Column(name = "fulfilled_loan_id", columnDefinition = "TEXT")
    private String fulfilledLoanId;

    @Column(name = "fulfilled_by", columnDefinition = "TEXT")
    private String fulfilledBy;

    @Column(name = "updated_at", columnDefinition = "TEXT")
    private String updatedAt;

    @Column(name = "aggregate_version", nullable = false)
    private int aggregateVersion = 1;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getBookId() { return bookId; }
    public void setBookId(String bookId) { this.bookId = bookId; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public int getQueueNo() { return queueNo; }
    public void setQueueNo(int queueNo) { this.queueNo = queueNo; }
    public String getHeldCopyId() { return heldCopyId; }
    public void setHeldCopyId(String heldCopyId) { this.heldCopyId = heldCopyId; }
    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
    public String getReadyAt() { return readyAt; }
    public void setReadyAt(String readyAt) { this.readyAt = readyAt; }
    public String getExpiresAt() { return expiresAt; }
    public void setExpiresAt(String expiresAt) { this.expiresAt = expiresAt; }
    public String getFulfilledAt() { return fulfilledAt; }
    public void setFulfilledAt(String fulfilledAt) { this.fulfilledAt = fulfilledAt; }
    public String getCancelledAt() { return cancelledAt; }
    public void setCancelledAt(String cancelledAt) { this.cancelledAt = cancelledAt; }
    public String getExpiredAt() { return expiredAt; }
    public void setExpiredAt(String expiredAt) { this.expiredAt = expiredAt; }
    public String getFulfilledLoanId() { return fulfilledLoanId; }
    public void setFulfilledLoanId(String fulfilledLoanId) { this.fulfilledLoanId = fulfilledLoanId; }
    public String getFulfilledBy() { return fulfilledBy; }
    public void setFulfilledBy(String fulfilledBy) { this.fulfilledBy = fulfilledBy; }
    public String getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(String updatedAt) { this.updatedAt = updatedAt; }
    public int getAggregateVersion() { return aggregateVersion; }
    public void setAggregateVersion(int aggregateVersion) { this.aggregateVersion = aggregateVersion; }
}
