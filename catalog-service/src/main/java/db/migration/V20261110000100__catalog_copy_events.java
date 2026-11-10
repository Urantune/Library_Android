package db.migration;

import java.sql.Connection;
import java.sql.Statement;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

public class V20261110000100__catalog_copy_events extends BaseJavaMigration {
    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        addColumn(connection, "acquired_at", "TEXT");
        addColumn(connection, "holder_type", "TEXT");
        addColumn(connection, "holder_id", "TEXT");
        addColumn(connection, "aggregate_version", "INTEGER NOT NULL DEFAULT 1");
        try (Statement statement = connection.createStatement()) {
            statement.execute("CREATE INDEX IF NOT EXISTS idx_publishers_status ON publishers(status)");
            statement.execute("CREATE TABLE IF NOT EXISTS outbox_events (id TEXT PRIMARY KEY NOT NULL, aggregate_type TEXT NOT NULL, aggregate_id TEXT NOT NULL, event_type TEXT NOT NULL, payload TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'PENDING', created_at TEXT NOT NULL, published_at TEXT, retry_count INTEGER NOT NULL DEFAULT 0, next_attempt_at TEXT, last_error TEXT)");
            statement.execute("CREATE TABLE IF NOT EXISTS processed_events (consumer_group TEXT NOT NULL, event_id TEXT NOT NULL, topic TEXT NOT NULL, processed_at TEXT NOT NULL, PRIMARY KEY (consumer_group, event_id))");
            statement.execute("CREATE TABLE IF NOT EXISTS copy_operations (id TEXT PRIMARY KEY NOT NULL, request_hash TEXT NOT NULL, operation_type TEXT NOT NULL, completed_at TEXT NOT NULL)");
        }
    }

    private void addColumn(Connection connection, String column, String type) throws Exception {
        try (Statement statement = connection.createStatement();
             var columns = statement.executeQuery("PRAGMA table_info(book_copies)")) {
            while (columns.next()) {
                if (column.equalsIgnoreCase(columns.getString("name"))) return;
            }
        }
        try (Statement statement = connection.createStatement()) {
            statement.execute("ALTER TABLE book_copies ADD COLUMN " + column + " " + type);
        }
    }
}
