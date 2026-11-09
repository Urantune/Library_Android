package catalogservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "processed_events")
public class ProcessedCatalogEvent {
    @EmbeddedId
    private ProcessedCatalogEventId id;

    @Column(nullable = false)
    private String topic;

    @Column(name = "processed_at", nullable = false)
    private String processedAt;

    protected ProcessedCatalogEvent() {
    }

    public ProcessedCatalogEvent(ProcessedCatalogEventId id, String topic, String processedAt) {
        this.id = id;
        this.topic = topic;
        this.processedAt = processedAt;
    }
}
