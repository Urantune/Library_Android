package catalogservice.config;

import java.util.Map;
import org.flywaydb.core.api.MigrationState;
import org.springframework.boot.flyway.autoconfigure.FlywayMigrationStrategy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

@Configuration
@Profile("local")
public class LocalFlywayConfig {
    @Bean
    FlywayMigrationStrategy catalogMigrationStrategy() {
        return flyway -> {
            Map<String, Integer> knownMissing = Map.of(
                "V20261108161500__publisher_indexes.sql", -45742044,
                "V20261108170000__catalog_copy_holders_and_outbox.sql", 702099812);
            for (var migration : flyway.info().all()) {
                if (migration.getState() == MigrationState.MISSING_SUCCESS || migration.getState() == MigrationState.MISSING_FAILED) {
                    Integer expected = knownMissing.get(migration.getScript());
                    if (migration.getState() != MigrationState.MISSING_SUCCESS || expected == null
                            || !expected.equals(migration.getAppliedChecksum())) {
                        throw new IllegalStateException("Unrecognized missing Flyway migration: " + migration.getScript());
                    }
                }
            }
            flyway.migrate();
        };
    }
}
