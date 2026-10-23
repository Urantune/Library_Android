package catalogservice.entity;

import catalogservice.persistence.UtcTimestampConverter;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import java.time.LocalDateTime;

@MappedSuperclass
public abstract class TimestampedEntity {

    @Convert(converter = UtcTimestampConverter.class)
    @Column(name = "created_at", columnDefinition = "TEXT", updatable = false, nullable = false)
    private LocalDateTime createdAt;

    @Convert(converter = UtcTimestampConverter.class)
    @Column(name = "updated_at", columnDefinition = "TEXT", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
