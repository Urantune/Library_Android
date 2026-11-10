package customer.reservationservice.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import customer.reservationservice.dto.ReservationDtos.KafkaEventEnvelope;
import customer.reservationservice.service.ReservationQueueService;
import java.util.Map;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Consumes library.copy.available.v1 from catalog-service to trigger FIFO reservation queue assignment.
 */
@Component
public class CopyAvailableConsumer {
    public static final String TOPIC_COPY_AVAILABLE = "library.copy.available.v1";

    private final ObjectMapper mapper;
    private final ReservationQueueService queueService;

    public CopyAvailableConsumer(ObjectMapper mapper, ReservationQueueService queueService) {
        this.mapper = mapper;
        this.queueService = queueService;
    }

    @KafkaListener(
            topics = TOPIC_COPY_AVAILABLE,
            groupId = ReservationQueueService.CONSUMER_GROUP_COPY_AVAILABLE
    )
    public void onCopyAvailable(String rawEvent) {
        KafkaEventEnvelope envelope;
        try {
            envelope = mapper.readValue(rawEvent, KafkaEventEnvelope.class);
        } catch (JsonProcessingException ex) {
            throw new IllegalArgumentException("Malformed CopyAvailable Kafka event JSON", ex);
        }
        onCopyAvailable(envelope);
    }

    public void onCopyAvailable(KafkaEventEnvelope event) {
        if (event == null || event.eventId() == null || event.eventId().isBlank()) {
            throw new IllegalArgumentException("CopyAvailable event missing eventId");
        }
        if (!TOPIC_COPY_AVAILABLE.equals(event.type())) {
            throw new IllegalArgumentException("Unexpected event type: " + event.type());
        }
        Map<String, Object> payload = event.payload();
        if (payload == null) {
            throw new IllegalArgumentException("CopyAvailable event missing payload");
        }
        String bookId = requireString(payload, "bookId");
        String copyId = requireString(payload, "copyId");
        queueService.assignNext(bookId, copyId, event.eventId().trim(), event.traceId());
    }

    private static String requireString(Map<String, Object> payload, String key) {
        Object val = payload.get(key);
        if (!(val instanceof String s) || s.isBlank()) {
            throw new IllegalArgumentException("Missing required CopyAvailable field: " + key);
        }
        return s.trim();
    }
}
