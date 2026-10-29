INSERT OR IGNORE INTO notifications (id, user_id, type, title, body, channel, reference_type, reference_id, is_read, created_at, sent_at)
VALUES ('notification-demo-001', 'user-demo-001', 'LOAN_DUE', 'Loan due soon', 'Your demo loan is due on 01 November 2026.', 'IN_APP', 'LOAN', 'loan-demo-001', 0, '2026-10-28T08:00:00Z', '2026-10-28T08:00:00Z');
