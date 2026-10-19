CREATE TABLE reservations (
    id TEXT NOT NULL PRIMARY KEY,
    user_id TEXT NOT NULL,
    book_id TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('WAITING', 'READY', 'FULFILLED', 'CANCELLED', 'EXPIRED')),
    queue_no INTEGER NOT NULL,
    created_at TEXT NOT NULL,
    ready_at TEXT,
    expires_at TEXT,
    fulfilled_at TEXT,
    cancelled_at TEXT
);
CREATE INDEX idx_reservations_user_id ON reservations(user_id);
CREATE INDEX idx_reservations_book_id ON reservations(book_id);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_queue_no ON reservations(queue_no);
CREATE INDEX idx_reservations_expires_at ON reservations(expires_at);

CREATE TABLE outbox_events (
    id TEXT NOT NULL PRIMARY KEY,
    aggregate_type TEXT NOT NULL,
    aggregate_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PUBLISHED', 'FAILED')),
    created_at TEXT NOT NULL,
    published_at TEXT
);
CREATE INDEX idx_outbox_events_status ON outbox_events(status);
