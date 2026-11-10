package customer.circulationservice.dto.response;

import java.util.Map;

public record LoanReturnedEvent(
        String eventId,
        String type,
        int schemaVersion,
        String occurredAt,
        String traceId,
        String aggregateId,
        long aggregateVersion,
        Map<String, Object> payload
) {
}
