CREATE TABLE notifications (
    id TEXT NOT NULL PRIMARY KEY,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    channel TEXT NOT NULL CHECK (channel IN ('IN_APP', 'PUSH')),
    reference_type TEXT,
    reference_id TEXT,
    is_read INTEGER NOT NULL DEFAULT 0 CHECK (is_read IN (0, 1)),
    read_at TEXT,
    created_at TEXT NOT NULL,
    sent_at TEXT
);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

CREATE TABLE device_tokens (
    id TEXT NOT NULL PRIMARY KEY,
    user_id TEXT NOT NULL,
    fcm_token TEXT NOT NULL UNIQUE,
    platform TEXT NOT NULL CHECK (platform IN ('ANDROID')),
    active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1)),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);
