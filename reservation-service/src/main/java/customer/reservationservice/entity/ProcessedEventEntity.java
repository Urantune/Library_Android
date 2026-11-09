package customer.reservationservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "processed_events")
public class ProcessedEventEntity {
    @EmbeddedId
    private ProcessedEventId id;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String topic;

    @Column(name = "processed_at", columnDefinition = "TEXT", nullable = false)
    private String processedAt;

    public ProcessedEventEntity() {
    }

    public ProcessedEventEntity(ProcessedEventId id, String topic, String processedAt) {
        this.id = id;
        this.topic = topic;
        this.processedAt = processedAt;
    }

    public ProcessedEventId getId() { return id; }
    public void setId(ProcessedEventId id) { this.id = id; }
    public String getTopic() { return topic; }
    public void setTopic(String topic) { this.topic = topic; }
    public String getProcessedAt() { return processedAt; }
    public void setProcessedAt(String processedAt) { this.processedAt = processedAt; }
}
