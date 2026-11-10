package customer.reservationservice.messaging;

import customer.reservationservice.entity.OutboxEventEntity;
import customer.reservationservice.repository.OutboxEventRepository;
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

/**
 * Publishes transactional outbox records to Kafka, awaiting broker ack before marking PUBLISHED,
 * with bounded exponential backoff and DLT routing upon exhausting retries.
 */
@Component
public class OutboxPublisher {
    private static final Logger log = LoggerFactory.getLogger(OutboxPublisher.class);

    private final OutboxEventRepository outboxEvents;
    private final KafkaOperations<String, String> kafkaOperations;
    private final TransactionTemplate transactionTemplate;
    private final Clock clock;
    private final int maxRetries;
    private final boolean jobsEnabled;
    @Value("${app.kafka.enabled:false}")
    private boolean kafkaEnabled;

    public OutboxPublisher(
            OutboxEventRepository outboxEvents,
            KafkaOperations<String, String> kafkaOperations,
            TransactionTemplate transactionTemplate,
            Clock clock,
            @Value("${app.reservation.outbox.max-retries:5}") int maxRetries,
            @Value("${app.reservation.jobs.enabled:true}") boolean jobsEnabled
    ) {
        this.outboxEvents = outboxEvents;
        this.kafkaOperations = kafkaOperations;
        this.transactionTemplate = transactionTemplate;
        this.clock = clock;
        this.maxRetries = maxRetries;
        this.jobsEnabled = jobsEnabled;
    }

    @Scheduled(fixedDelayString = "${app.reservation.outbox-poll-ms:5000}")
    public void scheduledPublish() {
        if (!jobsEnabled || !kafkaEnabled) {
            return;
        }
        publishPendingBatch(50);
    }

    public int publishPendingBatch(int limit) {
        if (limit < 1) {
            return 0;
        }
        Instant now = Instant.now(clock);
        List<OutboxEventEntity> batch = transactionTemplate.execute(
                tx -> outboxEvents.findDuePending(now.toString(), PageRequest.of(0, limit))
        );
        if (batch == null || batch.isEmpty()) {
            return 0;
        }

        int publishedCount = 0;
        for (OutboxEventEntity event : batch) {
            String targetTopic = (event.getTopic() == null || event.getTopic().isBlank())
                    ? event.getEventType()
                    : event.getTopic();
            try {
                // Wait synchronously for broker acknowledgement before marking PUBLISHED
                kafkaOperations.send(targetTopic, event.getAggregateId(), event.getPayload())
                        .get(5, TimeUnit.SECONDS);

                transactionTemplate.executeWithoutResult(tx -> outboxEvents.findById(event.getId()).ifPresent(row -> {
                    row.setStatus("PUBLISHED");
                    row.setPublishedAt(Instant.now(clock).toString());
                    row.setLastError(null);
                    outboxEvents.saveAndFlush(row);
                }));
                publishedCount++;
            } catch (Exception ex) {
                handlePublishFailure(event, targetTopic, ex);
            }
        }
        return publishedCount;
    }

    private void handlePublishFailure(OutboxEventEntity event, String targetTopic, Exception ex) {
        int nextAttempt = event.getRetryCount() + 1;
        Instant now = Instant.now(clock);
        boolean exhausted = nextAttempt >= maxRetries;

        if (exhausted) {
            try {
                kafkaOperations.send(targetTopic + ".dlt", event.getAggregateId(), event.getPayload())
                        .get(3, TimeUnit.SECONDS);
            } catch (Exception dltEx) {
                log.error("Failed forwarding exhausted outbox event={} to DLT {}.dlt",
                        event.getId(), targetTopic, dltEx);
            }
        }

        transactionTemplate.executeWithoutResult(tx -> outboxEvents.findById(event.getId()).ifPresent(row -> {
            row.setRetryCount(nextAttempt);
            row.setLastError(ex.getMessage());
            if (exhausted) {
                row.setStatus("FAILED");
                row.setNextAttemptAt(null);
            } else {
                long backoffSeconds = Math.min(60L, 1L << Math.min(nextAttempt, 6));
                row.setNextAttemptAt(now.plus(Duration.ofSeconds(backoffSeconds)).toString());
            }
            outboxEvents.saveAndFlush(row);
        }));
    }
}
