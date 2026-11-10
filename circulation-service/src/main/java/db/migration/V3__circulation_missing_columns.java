package db.migration;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

public class V3__circulation_missing_columns extends BaseJavaMigration {
    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        add(connection, "loans", "reservation_id", "TEXT");
        add(connection, "loans", "fulfillment_key", "TEXT");
        add(connection, "loans", "aggregate_version", "INTEGER NOT NULL DEFAULT 1");
        add(connection, "loan_items", "return_operation_id", "TEXT");
        add(connection, "outbox_events", "retry_count", "INTEGER NOT NULL DEFAULT 0");
        add(connection, "outbox_events", "next_attempt_at", "TEXT");
        add(connection, "outbox_events", "last_error", "TEXT");
        try (Statement statement = connection.createStatement()) {
            statement.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_loan_items_return_operation ON loan_items(return_operation_id)");
            statement.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_loans_fulfillment_key ON loans(fulfillment_key)");
        }
    }

    private void add(Connection connection, String table, String column, String definition) throws Exception {
        try (Statement statement = connection.createStatement(); ResultSet result = statement.executeQuery("PRAGMA table_info(" + table + ")")) {
            while (result.next()) if (column.equalsIgnoreCase(result.getString("name"))) return;
        }
        try (Statement statement = connection.createStatement()) {
            statement.execute("ALTER TABLE " + table + " ADD COLUMN " + column + " " + definition);
        }
    }
}
