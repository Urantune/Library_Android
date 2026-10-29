INSERT OR IGNORE INTO loans (id, user_id, status, requested_at, approved_at, borrowed_at, due_at, renew_count, created_at, updated_at)
VALUES ('loan-demo-001', 'user-demo-001', 'BORROWED', '2026-10-01T08:00:00Z', '2026-10-01T08:05:00Z', '2026-10-01T08:10:00Z', '2026-11-01T08:10:00Z', 0, '2026-10-01T08:00:00Z', '2026-10-01T08:10:00Z');

INSERT OR IGNORE INTO loan_items (id, loan_id, book_id, copy_id, item_status, fine_amount)
VALUES ('loan-item-demo-001', 'loan-demo-001', 'book-demo-001', 'copy-demo-001', 'BORROWED', 0);
