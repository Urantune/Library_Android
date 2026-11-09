package customer.notificationservice.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import customer.notificationservice.dto.NotificationDtos.ComposedNotification;
import customer.notificationservice.dto.NotificationDtos.KafkaEventEnvelope;
import customer.notificationservice.entity.NotificationEntity;
import customer.notificationservice.entity.ProcessedEventEntity;
import customer.notificationservice.entity.ProcessedEventId;
import customer.notificationservice.repository.NotificationRepository;
import customer.notificationservice.repository.ProcessedEventRepository;
import customer.notificationservice.service.DeviceTokenService;
import customer.notificationservice.service.NotificationComposer;
import customer.notificationservice.service.PushSender;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Consumes loan and reservation Kafka events with dedicated consumer groups per feature.
 * Commits IN_APP notification + processed_events deduplication atomically FIRST;
 * subsequent FCM push attempts execute outside the transaction and never roll back or delete IN_APP rows.
 */
@Component
public class NotificationEventConsumer {
    private static final Logger log = LoggerFactory.getLogger(NotificationEventConsumer.class);

    public static final String GROUP_LOAN_APPROVED = "notification-loan-approved-v1";
    public static final String GROUP_LOAN_RETURNED = "notification-loan-returned-v1";
    public static final String GROUP_LOAN_OVERDUE = "notification-loan-overdue-v1";
    public static final String GROUP_RESERVATION_READY = "notification-reservation-ready-v1";

    private final ObjectMapper mapper;
    private final NotificationComposer composer;
    private final NotificationRepository notifications;
    private final ProcessedEventRepository processedEvents;
    private final DeviceTokenService deviceTokenService;
    private final PushSender pushSender;
    private final TransactionTemplate transactionTemplate;
    private final Clock clock;

    public NotificationEventConsumer(
            ObjectMapper mapper,
            NotificationComposer composer,
            NotificationRepository notifications,
            ProcessedEventRepository processedEvents,
            DeviceTokenService deviceTokenService,
            PushSender pushSender,
            TransactionTemplate transactionTemplate,
            Clock clock
    ) {
        this.mapper = mapper;
        this.composer = composer;
        this.notifications = notifications;
        this.processedEvents = processedEvents;
        this.deviceTokenService = deviceTokenService;
        this.pushSender = pushSender;
        this.transactionTemplate = transactionTemplate;
        this.clock = clock;
    }

    @KafkaListener(
            topics = NotificationComposer.TOPIC_LOAN_APPROVED,
            groupId = GROUP_LOAN_APPROVED
    )
    public void onLoanApproved(String rawEvent) {
        processRawEvent(rawEvent, NotificationComposer.TOPIC_LOAN_APPROVED, GROUP_LOAN_APPROVED);
    }

    @KafkaListener(
            topics = NotificationComposer.TOPIC_LOAN_RETURNED,
            groupId = GROUP_LOAN_RETURNED
    )
    public void onLoanReturned(String rawEvent) {
        processRawEvent(rawEvent, NotificationComposer.TOPIC_LOAN_RETURNED, GROUP_LOAN_RETURNED);
    }

    @KafkaListener(
            topics = NotificationComposer.TOPIC_LOAN_OVERDUE,
            groupId = GROUP_LOAN_OVERDUE
    )
    public void onOverdue(String rawEvent) {
        processRawEvent(rawEvent, NotificationComposer.TOPIC_LOAN_OVERDUE, GROUP_LOAN_OVERDUE);
    }

    @KafkaListener(
            topics = NotificationComposer.TOPIC_RESERVATION_READY,
            groupId = GROUP_RESERVATION_READY
    )
    public void onReservationReady(String rawEvent) {
        processRawEvent(rawEvent, NotificationComposer.TOPIC_RESERVATION_READY, GROUP_RESERVATION_READY);
    }

    public void onLoanApproved(KafkaEventEnvelope event) {
        handleEnvelope(event, NotificationComposer.TOPIC_LOAN_APPROVED, GROUP_LOAN_APPROVED);
    }

    public void onLoanReturned(KafkaEventEnvelope event) {
        handleEnvelope(event, NotificationComposer.TOPIC_LOAN_RETURNED, GROUP_LOAN_RETURNED);
    }

    public void onOverdue(KafkaEventEnvelope event) {
        handleEnvelope(event, NotificationComposer.TOPIC_LOAN_OVERDUE, GROUP_LOAN_OVERDUE);
    }

    public void onReservationReady(KafkaEventEnvelope event) {
        handleEnvelope(event, NotificationComposer.TOPIC_RESERVATION_READY, GROUP_RESERVATION_READY);
    }

    private void processRawEvent(String rawEvent, String expectedTopic, String consumerGroup) {
        KafkaEventEnvelope envelope = parseEnvelope(rawEvent);
        handleEnvelope(envelope, expectedTopic, consumerGroup);
    }

    private void handleEnvelope(KafkaEventEnvelope envelope, String expectedTopic, String consumerGroup) {
        validateEnvelope(envelope, expectedTopic);

        // Step 1: Commit IN_APP notification + consumer dedup record in a single SQLite transaction
        Optional<ComposedNotification> created = transactionTemplate.execute(status -> {
            ProcessedEventId dedupId = new ProcessedEventId(consumerGroup, envelope.eventId().trim());
            if (processedEvents.existsById(dedupId)) {
                log.debug("Duplicate Kafka event skipped: group={}, eventId={}", consumerGroup, envelope.eventId());
                return Optional.empty();
            }

            ComposedNotification composed = composer.compose(envelope);
            String now = Instant.now(clock).toString();

            NotificationEntity entity = new NotificationEntity();
            entity.setId(UUID.randomUUID().toString());
            entity.setUserId(composed.userId());
            entity.setType(composed.type());
            entity.setTitle(composed.title());
            entity.setBody(composed.body());
            entity.setChannel("IN_APP");
            entity.setReferenceType(composed.referenceType());
            entity.setReferenceId(composed.referenceId());
            entity.setIsRead(0);
            entity.setCreatedAt(now);
            entity.setSentAt(now);
            notifications.saveAndFlush(entity);

            processedEvents.saveAndFlush(new ProcessedEventEntity(dedupId, expectedTopic, now));
            return Optional.of(composed);
        });

        // Step 2: Outside SQLite transaction, best-effort push delivery (never rolls back IN_APP)
        if (created != null && created.isPresent() && pushSender.isEnabled()) {
            ComposedNotification composed = created.get();
            try {
                List<String> tokens = deviceTokenService.findActiveTokensForUser(composed.userId());
                for (String token : tokens) {
                    try {
                        pushSender.send(token, composed);
                    } catch (RuntimeException pushEx) {
                        log.warn("Push delivery failed for user={} tokenPrefix={}; IN_APP notification preserved",
                                composed.userId(),
                                token.length() > 8 ? token.substring(0, 8) : "***",
                                pushEx);
                    }
                }
            } catch (RuntimeException lookupEx) {
                log.warn("Failed loading active device tokens for user={}; IN_APP notification preserved",
                        composed.userId(), lookupEx);
            }
        }
    }

    private KafkaEventEnvelope parseEnvelope(String rawEvent) {
        try {
            return mapper.readValue(rawEvent, KafkaEventEnvelope.class);
        } catch (JsonProcessingException ex) {
            throw new IllegalArgumentException("Malformed Kafka event JSON", ex);
        }
    }

    private static void validateEnvelope(KafkaEventEnvelope envelope, String expectedTopic) {
        if (envelope == null || envelope.eventId() == null || envelope.eventId().isBlank()) {
            throw new IllegalArgumentException("Kafka event envelope missing eventId");
        }
        if (!expectedTopic.equals(envelope.type())) {
            throw new IllegalArgumentException(
                    "Unexpected event type '" + envelope.type() + "' for topic '" + expectedTopic + "'"
            );
        }
    }
}
