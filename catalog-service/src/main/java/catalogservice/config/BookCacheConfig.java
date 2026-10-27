package catalogservice.config;

import java.time.Duration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.concurrent.ConcurrentMapCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;

@Configuration
@EnableCaching
public class BookCacheConfig {
    private static final String[] CACHES = {"book-pages", "book-details"};

    @Bean
    @ConditionalOnProperty(prefix = "app.cache", name = "provider", havingValue = "redis")
    CacheManager redisBookCacheManager(
        RedisConnectionFactory connectionFactory,
        @Value("${app.cache.ttl-seconds:300}") long ttlSeconds
    ) {
        var configuration = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofSeconds(ttlSeconds))
            .disableCachingNullValues();
        return RedisCacheManager.builder(connectionFactory).cacheDefaults(configuration).build();
    }

    @Bean
    @ConditionalOnMissingBean(CacheManager.class)
    CacheManager localBookCacheManager() {
        return new ConcurrentMapCacheManager(CACHES);
    }
}
