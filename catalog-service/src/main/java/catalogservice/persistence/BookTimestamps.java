package catalogservice.persistence;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

@MappedSuperclass
public abstract class BookTimestamps {
    @Convert(converter = UtcTimestampConverter.class)
    @Column(name = "created_at", columnDefinition = "TEXT", updatable = false, nullable = false)
    private LocalDateTime createdAt;

    @Convert(converter = UtcTimestampConverter.class)
    @Column(name = "updated_at", columnDefinition = "TEXT", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now(ZoneOffset.UTC);
        updatedAt = createdAt;
    }

    @PreUpdate
    protected void onUpdate() { updatedAt = LocalDateTime.now(ZoneOffset.UTC); }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
