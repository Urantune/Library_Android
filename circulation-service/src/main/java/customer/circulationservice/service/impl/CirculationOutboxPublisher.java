package customer.circulationservice.service.impl;

import customer.circulationservice.entity.CirculationOutboxEvent;
import customer.circulationservice.repository.CirculationOutboxRepository;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.concurrent.TimeUnit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.kafka.core.KafkaOperations;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

@Component
public class CirculationOutboxPublisher {
    private static final Logger log = LoggerFactory.getLogger(CirculationOutboxPublisher.class);

    private final CirculationOutboxRepository outbox;
    private final KafkaOperations<String, String> kafka;
    private final TransactionTemplate transactions;
    private final Clock clock;
    private final int maxRetries;
    @Value("${app.kafka.enabled:false}")
    private boolean kafkaEnabled;

    public CirculationOutboxPublisher(
            CirculationOutboxRepository outbox,
            KafkaOperations<String, String> kafka,
            TransactionTemplate transactions,
            Clock clock,
            @Value("${app.circulation.outbox.max-retries:5}") int maxRetries
    ) {
        this.outbox = outbox;
        this.kafka = kafka;
        this.transactions = transactions;
        this.clock = clock;
        this.maxRetries = Math.max(1, maxRetries);
    }

    @Scheduled(fixedDelayString = "${app.circulation.outbox-poll-ms:5000}")
    public void scheduledPublish() {
        if (!kafkaEnabled) return;
        publishPendingBatch(50);
    }

    public int publishPendingBatch(int limit) {
        if (limit < 1) return 0;
        String now = Instant.now(clock).toString();
        List<CirculationOutboxEvent> batch = transactions.execute(
                tx -> outbox.findDuePending(now, PageRequest.of(0, limit)));
        if (batch == null) return 0;

        int count = 0;
        for (CirculationOutboxEvent event : batch) {
            try {
                kafka.send(event.getEventType(), event.getAggregateId(), event.getPayload()).get(5, TimeUnit.SECONDS);
                transactions.executeWithoutResult(tx -> outbox.findById(event.getId()).ifPresent(row -> {
                    row.setStatus("PUBLISHED");
                    row.setPublishedAt(Instant.now(clock).toString());
                    row.setLastError(null);
                    outbox.saveAndFlush(row);
                }));
                count++;
            } catch (Exception ex) {
                handleFailure(event, ex);
            }
        }
        return count;
    }

    private void handleFailure(CirculationOutboxEvent event, Exception failure) {
        int retry = event.getRetryCount() + 1;
        Instant now = Instant.now(clock);
        if (retry >= maxRetries) {
            try {
                kafka.send(event.getEventType() + ".dlt", event.getAggregateId(), event.getPayload())
                        .get(3, TimeUnit.SECONDS);
            } catch (Exception dltFailure) {
                log.error("Could not publish circulation outbox event {} to DLT", event.getId(), dltFailure);
            }
        }
        transactions.executeWithoutResult(tx -> outbox.findById(event.getId()).ifPresent(row -> {
            row.setRetryCount(retry);
            row.setLastError(failure.getMessage());
            if (retry >= maxRetries) {
                row.setStatus("FAILED");
                row.setNextAttemptAt(null);
            } else {
                row.setNextAttemptAt(now.plus(Duration.ofSeconds(Math.min(60, 1L << Math.min(retry, 6)))).toString());
            }
            outbox.saveAndFlush(row);
        }));
    }
}
