CREATE TABLE IF NOT EXISTS processed_events (
    consumer_group TEXT NOT NULL,
    event_id TEXT NOT NULL,
    topic TEXT NOT NULL,
    processed_at TEXT NOT NULL,
    PRIMARY KEY (consumer_group, event_id)
);
