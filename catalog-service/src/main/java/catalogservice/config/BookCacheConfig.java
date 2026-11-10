package catalogservice.config;

import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.CachingConfigurer;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.concurrent.ConcurrentMapCacheManager;
import org.springframework.cache.interceptor.CacheErrorHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;

@Configuration
@EnableCaching
public class BookCacheConfig implements CachingConfigurer {
    private static final Logger log = LoggerFactory.getLogger(BookCacheConfig.class);
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

    @Override
    public CacheErrorHandler errorHandler() {
        return new CacheErrorHandler() {
            @Override
            public void handleCacheGetError(RuntimeException exception, Cache cache, Object key) {
                log.warn("Cache GET failed for key {}: {}. Falling back to database.", key, exception.getMessage());
            }

            @Override
            public void handleCachePutError(RuntimeException exception, Cache cache, Object key, Object value) {
                log.warn("Cache PUT failed for key {}: {}. Proceeding without cache.", key, exception.getMessage());
            }

            @Override
            public void handleCacheEvictError(RuntimeException exception, Cache cache, Object key) {
                log.warn("Cache EVICT failed for key {}: {}.", key, exception.getMessage());
            }

            @Override
            public void handleCacheClearError(RuntimeException exception, Cache cache) {
                log.warn("Cache CLEAR failed: {}.", exception.getMessage());
            }
        };
    }
}
