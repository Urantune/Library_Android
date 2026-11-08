package customer.reservationservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "reservations")
public class Reservation {

    @Id
    @Column(name = "id", nullable = false)
    private String id;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @Column(name = "book_id", nullable = false)
    private String bookId;

    @Column(name = "status", nullable = false)
    private String status;
    // Gợi ý: Bạn có thể thay thế bằng Enum nếu muốn kiểm soát chặt chẽ các trạng thái:
    // 'WAITING', 'READY', 'FULFILLED', 'CANCELLED', 'EXPIRED'

    @Column(name = "queue_no", nullable = false)
    private Integer queueNo;

    @Column(name = "created_at", nullable = false)
    private String createdAt;
    // Lưu ý: SQLite lưu ngày giờ dưới dạng TEXT, bạn có thể dùng String hoặc
    // dùng AttributeConverter/LocalDateTime nếu cần thiết.

    @Column(name = "ready_at")
    private String readyAt;

    @Column(name = "expires_at")
    private String expiresAt;

    @Column(name = "fulfilled_at")
    private String fulfilledAt;

    @Column(name = "cancelled_at")
    private String cancelledAt;

    // --- Constructors ---
    public Reservation() {
    }

    public Reservation(String id, String userId, String bookId, String status, Integer queueNo, String createdAt) {
        this.id = id;
        this.userId = userId;
        this.bookId = bookId;
        this.status = status;
        this.queueNo = queueNo;
        this.createdAt = createdAt;
    }

    // --- Getters and Setters ---
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getBookId() {
        return bookId;
    }

    public void setBookId(String bookId) {
        this.bookId = bookId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Integer getQueueNo() {
        return queueNo;
    }

    public void setQueueNo(Integer queueNo) {
        this.queueNo = queueNo;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }

    public String getReadyAt() {
        return readyAt;
    }

    public void setReadyAt(String readyAt) {
        this.readyAt = readyAt;
    }

    public String getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(String expiresAt) {
        this.expiresAt = expiresAt;
    }

    public String getFulfilledAt() {
        return fulfilledAt;
    }

    public void setFulfilledAt(String fulfilledAt) {
        this.fulfilledAt = fulfilledAt;
    }

    public String getCancelledAt() {
        return cancelledAt;
    }

    public void setCancelledAt(String cancelledAt) {
        this.cancelledAt = cancelledAt;
    }
}
