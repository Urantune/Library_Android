package db.migration;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

public class V20261111150000__reservation_runtime_schema extends BaseJavaMigration {
    @Override
    public void migrate(Context context) throws Exception {
        Connection db = context.getConnection();
        add(db, "reservations", "held_copy_id", "TEXT");
        add(db, "reservations", "expired_at", "TEXT");
        add(db, "reservations", "fulfilled_loan_id", "TEXT");
        add(db, "reservations", "fulfilled_by", "TEXT");
        add(db, "reservations", "updated_at", "TEXT");
        add(db, "reservations", "aggregate_version", "INTEGER NOT NULL DEFAULT 1");
        add(db, "outbox_events", "topic", "TEXT");
        add(db, "outbox_events", "trace_id", "TEXT");
        add(db, "outbox_events", "retry_count", "INTEGER NOT NULL DEFAULT 0");
        add(db, "outbox_events", "next_attempt_at", "TEXT");
        add(db, "outbox_events", "last_error", "TEXT");
        try (Statement s = db.createStatement()) {
            s.execute("CREATE TABLE IF NOT EXISTS processed_events (consumer_group TEXT NOT NULL, event_id TEXT NOT NULL, topic TEXT NOT NULL, processed_at TEXT NOT NULL, PRIMARY KEY (consumer_group, event_id))");
            s.execute("CREATE TABLE IF NOT EXISTS idempotency_records (id TEXT NOT NULL PRIMARY KEY, actor_id TEXT NOT NULL, operation TEXT NOT NULL, idempotency_key TEXT NOT NULL, request_hash TEXT NOT NULL, response_status INTEGER NOT NULL, response_body TEXT NOT NULL, created_at TEXT NOT NULL, UNIQUE (actor_id, operation, idempotency_key))");
            s.execute("CREATE TABLE IF NOT EXISTS reservation_operations (id TEXT NOT NULL PRIMARY KEY, reservation_id TEXT NOT NULL, operation_type TEXT NOT NULL, status TEXT NOT NULL, book_id TEXT NOT NULL, copy_id TEXT, target_loan_id TEXT, actor_id TEXT, attempt_count INTEGER NOT NULL DEFAULT 0, next_retry_at TEXT, last_error TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, idempotency_key TEXT, request_hash TEXT)");
            s.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_reservation_operation_idempotency ON reservation_operations(actor_id, operation_type, idempotency_key) WHERE idempotency_key IS NOT NULL");
        }
    }

    private void add(Connection db, String table, String column, String definition) throws Exception {
        try (Statement s = db.createStatement(); ResultSet rows = s.executeQuery("PRAGMA table_info(" + table + ")")) {
            while (rows.next()) if (column.equalsIgnoreCase(rows.getString("name"))) return;
        }
        try (Statement s = db.createStatement()) {
            s.execute("ALTER TABLE " + table + " ADD COLUMN " + column + " " + definition);
        }
    }
}
