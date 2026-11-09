package catalogservice.messaging;

import catalogservice.dto.response.LoanReturnedEvent;
import catalogservice.service.CopyInventoryService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class LoanReturnedConsumer {
    public static final String TOPIC = "library.loan.returned.v1";
    public static final String GROUP_ID = "catalog-loan-returned-v1";

    private final ObjectMapper mapper;
    private final CopyInventoryService inventory;

    public LoanReturnedConsumer(ObjectMapper mapper, CopyInventoryService inventory) {
        this.mapper = mapper;
        this.inventory = inventory;
    }

    @KafkaListener(topics = TOPIC, groupId = GROUP_ID)
    public void onLoanReturned(String rawEvent) {
        try {
            inventory.onLoanReturned(mapper.readValue(rawEvent, LoanReturnedEvent.class));
        } catch (JsonProcessingException ex) {
            throw new IllegalArgumentException("Malformed loan-returned event", ex);
        }
    }
}
