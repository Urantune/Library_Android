package customer.reservationservice.config;

import java.util.Map;
import java.util.Objects;
import org.flywaydb.core.api.MigrationState;
import org.springframework.boot.flyway.autoconfigure.FlywayMigrationStrategy;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

@Configuration
@Profile("local")
public class LocalFlywayConfig {
    @Bean
    FlywayMigrationStrategy reservationMigrationStrategy() {
        return flyway -> {
            Map<String, Integer> known = Map.of(
                "V20261108162000__reservation_queue_ops_and_dedup.sql", -342714603,
                "V20261108170000__fulfill_recovery_metadata.sql", -1862514734);
            String javaMigration = "db.migration.V20261109220000__RepairReservationWorkflowSchema";
            for (var migration : flyway.info().all()) {
                if (migration.getState() == MigrationState.MISSING_SUCCESS || migration.getState() == MigrationState.MISSING_FAILED) {
                    boolean validSql = known.containsKey(migration.getScript()) && Objects.equals(known.get(migration.getScript()), migration.getAppliedChecksum());
                    boolean validJava = javaMigration.equals(migration.getScript()) && migration.getAppliedChecksum() == null;
                    if (migration.getState() != MigrationState.MISSING_SUCCESS || !(validSql || validJava)) {
                        throw new IllegalStateException("Unrecognized missing Flyway migration: " + migration.getScript());
                    }
                }
            }
            flyway.migrate();
        };
    }
}
