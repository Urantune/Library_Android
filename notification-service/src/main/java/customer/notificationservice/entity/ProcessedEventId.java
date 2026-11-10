package customer.notificationservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class ProcessedEventId implements Serializable {
    @Column(name = "consumer_group", columnDefinition = "TEXT", nullable = false)
    private String consumerGroup;

    @Column(name = "event_id", columnDefinition = "TEXT", nullable = false)
    private String eventId;

    public ProcessedEventId() {
    }

    public ProcessedEventId(String consumerGroup, String eventId) {
        this.consumerGroup = consumerGroup;
        this.eventId = eventId;
    }

    public String getConsumerGroup() { return consumerGroup; }
    public void setConsumerGroup(String consumerGroup) { this.consumerGroup = consumerGroup; }
    public String getEventId() { return eventId; }
    public void setEventId(String eventId) { this.eventId = eventId; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ProcessedEventId that)) return false;
        return Objects.equals(consumerGroup, that.consumerGroup) && Objects.equals(eventId, that.eventId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(consumerGroup, eventId);
    }
}
