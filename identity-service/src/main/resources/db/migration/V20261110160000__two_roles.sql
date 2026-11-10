CREATE TABLE roles_v2 (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL UNIQUE CHECK (code IN ('ADMIN', 'USER')),
    name TEXT NOT NULL
);

INSERT INTO roles_v2(id, code, name) VALUES (1, 'USER', 'User'), (4, 'ADMIN', 'Admin');

CREATE TABLE user_roles_v2 (
    user_id TEXT NOT NULL,
    role_id INTEGER NOT NULL,
    assigned_at TEXT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (role_id) REFERENCES roles_v2(id)
);

INSERT OR IGNORE INTO user_roles_v2(user_id, role_id, assigned_at)
SELECT ur.user_id, CASE WHEN r.code = 'MEMBER' THEN 1 ELSE 4 END, ur.assigned_at
FROM user_roles ur JOIN roles r ON r.id = ur.role_id;

DROP TABLE user_roles;
DROP TABLE roles;
ALTER TABLE roles_v2 RENAME TO roles;
ALTER TABLE user_roles_v2 RENAME TO user_roles;
