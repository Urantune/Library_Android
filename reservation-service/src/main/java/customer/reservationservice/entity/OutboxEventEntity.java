package customer.reservationservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "outbox_events")
public class OutboxEventEntity {
    @Id
    @Column(columnDefinition = "TEXT", nullable = false)
    private String id;

    @Column(name = "aggregate_type", columnDefinition = "TEXT", nullable = false)
    private String aggregateType;

    @Column(name = "aggregate_id", columnDefinition = "TEXT", nullable = false)
    private String aggregateId;

    @Column(name = "event_type", columnDefinition = "TEXT", nullable = false)
    private String eventType;

    @Column(columnDefinition = "TEXT")
    private String topic;

    @Column(name = "trace_id", columnDefinition = "TEXT")
    private String traceId;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String payload;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String status = "PENDING";

    @Column(name = "retry_count", nullable = false)
    private int retryCount;

    @Column(name = "next_attempt_at", columnDefinition = "TEXT")
    private String nextAttemptAt;

    @Column(name = "last_error", columnDefinition = "TEXT")
    private String lastError;

    @Column(name = "created_at", columnDefinition = "TEXT", nullable = false)
    private String createdAt;

    @Column(name = "published_at", columnDefinition = "TEXT")
    private String publishedAt;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getAggregateType() { return aggregateType; }
    public void setAggregateType(String aggregateType) { this.aggregateType = aggregateType; }
    public String getAggregateId() { return aggregateId; }
    public void setAggregateId(String aggregateId) { this.aggregateId = aggregateId; }
    public String getEventType() { return eventType; }
    public void setEventType(String eventType) { this.eventType = eventType; }
    public String getTopic() { return topic; }
    public void setTopic(String topic) { this.topic = topic; }
    public String getTraceId() { return traceId; }
    public void setTraceId(String traceId) { this.traceId = traceId; }
    public String getPayload() { return payload; }
    public void setPayload(String payload) { this.payload = payload; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public int getRetryCount() { return retryCount; }
    public void setRetryCount(int retryCount) { this.retryCount = retryCount; }
    public String getNextAttemptAt() { return nextAttemptAt; }
    public void setNextAttemptAt(String nextAttemptAt) { this.nextAttemptAt = nextAttemptAt; }
    public String getLastError() { return lastError; }
    public void setLastError(String lastError) { this.lastError = lastError; }
    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
    public String getPublishedAt() { return publishedAt; }
    public void setPublishedAt(String publishedAt) { this.publishedAt = publishedAt; }
}
