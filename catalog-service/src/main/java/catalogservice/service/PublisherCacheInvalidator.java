package catalogservice.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/**
 * Shared cache invalidation component for Publisher writes.
 * Evicts Catalog book caches AFTER SQLite transaction commit so uncommitted state is never exposed,
 * and tolerates cache/Redis outages without rolling back committed SQLite writes.
 */
@Component
public class PublisherCacheInvalidator {
    private static final Logger log = LoggerFactory.getLogger(PublisherCacheInvalidator.class);
    private static final String[] BOOK_CACHES = {"book-pages", "book-details"};

    private final CacheManager cacheManager;

    public PublisherCacheInvalidator(CacheManager cacheManager) {
        this.cacheManager = cacheManager;
    }

    public void evictBookCachesAfterCommit() {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    clearBookCachesSafely();
                }
            });
        } else {
            clearBookCachesSafely();
        }
    }

    private void clearBookCachesSafely() {
        for (String cacheName : BOOK_CACHES) {
            try {
                Cache cache = cacheManager.getCache(cacheName);
                if (cache != null) {
                    cache.clear();
                }
            } catch (RuntimeException ex) {
                log.warn("Failed to evict catalog cache '{}' after publisher mutation; continuing with SQLite source of truth",
                        cacheName, ex);
            }
        }
    }
}
