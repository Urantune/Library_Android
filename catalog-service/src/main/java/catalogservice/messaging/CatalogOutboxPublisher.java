package catalogservice.messaging;

import catalogservice.entity.CatalogOutboxEvent;
import catalogservice.repository.CatalogOutboxRepository;
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
public class CatalogOutboxPublisher {
    private static final Logger log = LoggerFactory.getLogger(CatalogOutboxPublisher.class);

    private final CatalogOutboxRepository events;
    private final KafkaOperations<String, String> kafka;
    private final TransactionTemplate transactions;
    private final Clock clock;
    private final int maxRetries;
    @Value("${app.kafka.enabled:false}")
    private boolean kafkaEnabled;

    public CatalogOutboxPublisher(
            CatalogOutboxRepository events,
            KafkaOperations<String, String> kafka,
            TransactionTemplate transactions,
            Clock clock,
            @Value("${app.catalog.outbox.max-retries:5}") int maxRetries
    ) {
        this.events = events;
        this.kafka = kafka;
        this.transactions = transactions;
        this.clock = clock;
        this.maxRetries = Math.max(1, maxRetries);
    }

    @Scheduled(fixedDelayString = "${app.catalog.outbox-poll-ms:5000}")
    public void scheduledPublish() {
        if (!kafkaEnabled) return;
        publishPendingBatch(50);
    }

    public int publishPendingBatch(int limit) {
        if (limit < 1) return 0;
        String now = Instant.now(clock).toString();
        List<CatalogOutboxEvent> batch = transactions.execute(
                tx -> events.findDuePending(now, PageRequest.of(0, limit)));
        if (batch == null) return 0;

        int published = 0;
        for (CatalogOutboxEvent event : batch) {
            try {
                kafka.send(event.getEventType(), event.getAggregateId(), event.getPayload()).get(5, TimeUnit.SECONDS);
                transactions.executeWithoutResult(tx -> events.findById(event.getId()).ifPresent(row -> {
                    row.setStatus("PUBLISHED");
                    row.setPublishedAt(Instant.now(clock).toString());
                    row.setLastError(null);
                    events.saveAndFlush(row);
                }));
                published++;
            } catch (Exception ex) {
                handleFailure(event, ex);
            }
        }
        return published;
    }

    private void handleFailure(CatalogOutboxEvent event, Exception failure) {
        int retry = event.getRetryCount() + 1;
        Instant now = Instant.now(clock);
        boolean forwarded = false;
        if (retry >= maxRetries) {
            try {
                kafka.send(event.getEventType() + ".dlt", event.getAggregateId(), event.getPayload())
                        .get(3, TimeUnit.SECONDS);
                forwarded = true;
            } catch (Exception dltFailure) {
                log.error("Could not publish catalog outbox event {} to DLT", event.getId(), dltFailure);
            }
        }
        boolean deadLetterDelivered = forwarded;
        transactions.executeWithoutResult(tx -> events.findById(event.getId()).ifPresent(row -> {
            row.setRetryCount(retry);
            row.setLastError(failure.getMessage());
            if (deadLetterDelivered) {
                row.setStatus("FAILED");
                row.setNextAttemptAt(null);
            } else {
                row.setNextAttemptAt(now.plus(Duration.ofSeconds(Math.min(60, 1L << Math.min(retry, 6)))).toString());
            }
            events.saveAndFlush(row);
        }));
    }
}
