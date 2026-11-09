package customer.circulationservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "outbox_events")
public class CirculationOutboxEvent {
    @Id
    private String id;
    @Column(name = "aggregate_type", nullable = false)
    private String aggregateType;
    @Column(name = "aggregate_id", nullable = false)
    private String aggregateId;
    @Column(name = "event_type", nullable = false)
    private String eventType;
    @Column(nullable = false)
    private String payload;
    @Column(nullable = false)
    private String status = "PENDING";
    @Column(name = "created_at", nullable = false)
    private String createdAt;
    @Column(name = "published_at")
    private String publishedAt;
    @Column(name = "retry_count", nullable = false)
    private int retryCount;
    @Column(name = "next_attempt_at")
    private String nextAttemptAt;
    @Column(name = "last_error")
    private String lastError;

    protected CirculationOutboxEvent() {
    }

    public CirculationOutboxEvent(String id, String aggregateId, String eventType, String payload, String createdAt) {
        this.id = id;
        this.aggregateType = "LOAN";
        this.aggregateId = aggregateId;
        this.eventType = eventType;
        this.payload = payload;
        this.createdAt = createdAt;
    }

    public String getId() { return id; }
    public String getAggregateId() { return aggregateId; }
    public String getEventType() { return eventType; }
    public String getPayload() { return payload; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getPublishedAt() { return publishedAt; }
    public void setPublishedAt(String publishedAt) { this.publishedAt = publishedAt; }
    public int getRetryCount() { return retryCount; }
    public void setRetryCount(int retryCount) { this.retryCount = retryCount; }
    public String getNextAttemptAt() { return nextAttemptAt; }
    public void setNextAttemptAt(String nextAttemptAt) { this.nextAttemptAt = nextAttemptAt; }
    public String getLastError() { return lastError; }
    public void setLastError(String lastError) { this.lastError = lastError; }
}
