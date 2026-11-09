package catalogservice.entity;

import java.io.Serializable;
import java.util.Objects;
import jakarta.persistence.Embeddable;

@Embeddable
public class ProcessedCatalogEventId implements Serializable {
    @jakarta.persistence.Column(name = "consumer_group", nullable = false)
    private String consumerGroup;
    @jakarta.persistence.Column(name = "event_id", nullable = false)
    private String eventId;

    public ProcessedCatalogEventId() {
    }

    public ProcessedCatalogEventId(String consumerGroup, String eventId) {
        this.consumerGroup = consumerGroup;
        this.eventId = eventId;
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) return true;
        if (!(other instanceof ProcessedCatalogEventId that)) return false;
        return Objects.equals(consumerGroup, that.consumerGroup) && Objects.equals(eventId, that.eventId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(consumerGroup, eventId);
    }
}
