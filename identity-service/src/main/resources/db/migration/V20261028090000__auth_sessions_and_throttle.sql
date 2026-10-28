CREATE TABLE auth_sessions (
    id TEXT NOT NULL PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id),
    expires_at TEXT NOT NULL,
    revoked_at TEXT,
    created_at TEXT NOT NULL
);
CREATE INDEX idx_auth_sessions_user ON auth_sessions(user_id);
ALTER TABLE refresh_tokens ADD COLUMN session_id TEXT REFERENCES auth_sessions(id);
CREATE INDEX idx_refresh_tokens_session ON refresh_tokens(session_id);
CREATE TABLE auth_throttle (
    bucket_key TEXT NOT NULL PRIMARY KEY,
    attempts INTEGER NOT NULL,
    ends_at INTEGER NOT NULL
);
CREATE INDEX idx_auth_throttle_expiry ON auth_throttle(ends_at);
INSERT OR IGNORE INTO roles(code,name) VALUES('MEMBER','Bạn đọc');
