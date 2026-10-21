ALTER TABLE books ADD COLUMN page_count INTEGER CHECK (page_count IS NULL OR page_count > 0);
ALTER TABLE book_copies ADD COLUMN acquired_at TEXT;
