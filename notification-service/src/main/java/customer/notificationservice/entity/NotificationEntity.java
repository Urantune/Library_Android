package customer.notificationservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "notifications")
public class NotificationEntity {
    @Id
    @Column(columnDefinition = "TEXT", nullable = false)
    private String id;

    @Column(name = "user_id", columnDefinition = "TEXT", nullable = false)
    private String userId;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String type;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String body;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String channel;

    @Column(name = "reference_type", columnDefinition = "TEXT")
    private String referenceType;

    @Column(name = "reference_id", columnDefinition = "TEXT")
    private String referenceId;

    @Column(name = "is_read", nullable = false)
    private int isRead;

    @Column(name = "read_at", columnDefinition = "TEXT")
    private String readAt;

    @Column(name = "created_at", columnDefinition = "TEXT", nullable = false)
    private String createdAt;

    @Column(name = "sent_at", columnDefinition = "TEXT")
    private String sentAt;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }
    public String getChannel() { return channel; }
    public void setChannel(String channel) { this.channel = channel; }
    public String getReferenceType() { return referenceType; }
    public void setReferenceType(String referenceType) { this.referenceType = referenceType; }
    public String getReferenceId() { return referenceId; }
    public void setReferenceId(String referenceId) { this.referenceId = referenceId; }
    public int getIsRead() { return isRead; }
    public void setIsRead(int isRead) { this.isRead = isRead; }
    public String getReadAt() { return readAt; }
    public void setReadAt(String readAt) { this.readAt = readAt; }
    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
    public String getSentAt() { return sentAt; }
    public void setSentAt(String sentAt) { this.sentAt = sentAt; }
}
