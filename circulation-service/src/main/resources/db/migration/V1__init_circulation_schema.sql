CREATE TABLE loans (
    id TEXT NOT NULL PRIMARY KEY,
    user_id TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('REQUESTED', 'APPROVED', 'BORROWED', 'RETURNED', 'REJECTED', 'OVERDUE', 'CANCELLED')),
    requested_at TEXT NOT NULL,
    approved_at TEXT,
    borrowed_at TEXT,
    due_at TEXT,
    returned_at TEXT,
    processed_by TEXT,
    rejection_reason TEXT,
    renew_count INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
CREATE INDEX idx_loans_user_id ON loans(user_id);
CREATE INDEX idx_loans_status ON loans(status);
CREATE INDEX idx_loans_due_at ON loans(due_at);

CREATE TABLE loan_items (
    id TEXT NOT NULL PRIMARY KEY,
    loan_id TEXT NOT NULL,
    book_id TEXT NOT NULL,
    copy_id TEXT,
    item_status TEXT NOT NULL CHECK (item_status IN ('REQUESTED', 'BORROWED', 'RETURNED', 'LOST')),
    returned_at TEXT,
    condition_on_return TEXT,
    fine_amount REAL NOT NULL DEFAULT 0,
    FOREIGN KEY (loan_id) REFERENCES loans(id)
);
CREATE INDEX idx_loan_items_loan_id ON loan_items(loan_id);
CREATE INDEX idx_loan_items_book_id ON loan_items(book_id);
CREATE INDEX idx_loan_items_item_status ON loan_items(item_status);

CREATE TABLE loan_renewals (
    id TEXT NOT NULL PRIMARY KEY,
    loan_id TEXT NOT NULL,
    requested_by TEXT NOT NULL,
    requested_at TEXT NOT NULL,
    previous_due_at TEXT NOT NULL,
    new_due_at TEXT,
    status TEXT NOT NULL CHECK (status IN ('REQUESTED', 'APPROVED', 'REJECTED')),
    approved_by TEXT,
    decision_at TEXT,
    reason TEXT,
    FOREIGN KEY (loan_id) REFERENCES loans(id)
);
CREATE INDEX idx_loan_renewals_loan_id ON loan_renewals(loan_id);

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
