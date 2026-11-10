package customer.circulationservice.config;

import java.time.Clock;
import org.apache.kafka.common.TopicPartition;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.KafkaOperations;
import org.springframework.kafka.listener.CommonErrorHandler;
import org.springframework.kafka.listener.DeadLetterPublishingRecoverer;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.util.backoff.FixedBackOff;

@Configuration
@EnableScheduling
public class CirculationKafkaConfig {
    @Bean
    Clock circulationClock() {
        return Clock.systemUTC();
    }

    @Bean
    @ConditionalOnBean(KafkaOperations.class)
    CommonErrorHandler circulationKafkaErrorHandler(KafkaOperations<Object, Object> kafkaOperations) {
        DeadLetterPublishingRecoverer recoverer = new DeadLetterPublishingRecoverer(
                kafkaOperations,
                (record, ex) -> new TopicPartition(record.topic() + ".dlt", record.partition())
        );
        return new DefaultErrorHandler(recoverer, new FixedBackOff(1000L, 2L));
    }
}
