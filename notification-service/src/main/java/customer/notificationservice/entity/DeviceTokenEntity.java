package customer.notificationservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "device_tokens")
public class DeviceTokenEntity {
    @Id
    @Column(columnDefinition = "TEXT", nullable = false)
    private String id;

    @Column(name = "user_id", columnDefinition = "TEXT", nullable = false)
    private String userId;

    @Column(name = "fcm_token", columnDefinition = "TEXT", nullable = false, unique = true)
    private String fcmToken;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String platform;

    @Column(nullable = false)
    private int active = 1;

    @Column(name = "created_at", columnDefinition = "TEXT", nullable = false)
    private String createdAt;

    @Column(name = "updated_at", columnDefinition = "TEXT", nullable = false)
    private String updatedAt;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getFcmToken() { return fcmToken; }
    public void setFcmToken(String fcmToken) { this.fcmToken = fcmToken; }
    public String getPlatform() { return platform; }
    public void setPlatform(String platform) { this.platform = platform; }
    public int getActive() { return active; }
    public void setActive(int active) { this.active = active; }
    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
    public String getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(String updatedAt) { this.updatedAt = updatedAt; }
}
