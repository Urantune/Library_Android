CREATE TABLE publishers (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    address TEXT,
    email TEXT,
    phone TEXT,
    website TEXT,
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE authors (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    bio TEXT,
    birth_date TEXT,
    country TEXT,
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
CREATE INDEX idx_authors_name ON authors(name);

CREATE TABLE categories (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    parent_id TEXT,
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (parent_id) REFERENCES categories(id)
);

CREATE TABLE books (
    id TEXT NOT NULL PRIMARY KEY,
    isbn TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    description TEXT,
    publisher_id TEXT,
    publication_year INTEGER,
    language TEXT,
    cover_url TEXT,
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (publisher_id) REFERENCES publishers(id)
);
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_publisher_id ON books(publisher_id);
CREATE INDEX idx_books_status ON books(status);

CREATE TABLE book_authors (
    book_id TEXT NOT NULL,
    author_id TEXT NOT NULL,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(id),
    FOREIGN KEY (author_id) REFERENCES authors(id)
);

CREATE TABLE book_categories (
    book_id TEXT NOT NULL,
    category_id TEXT NOT NULL,
    PRIMARY KEY (book_id, category_id),
    FOREIGN KEY (book_id) REFERENCES books(id),
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE book_copies (
    id TEXT NOT NULL PRIMARY KEY,
    book_id TEXT NOT NULL,
    accession_code TEXT NOT NULL UNIQUE,
    barcode TEXT UNIQUE,
    qr_value TEXT UNIQUE,
    shelf_location TEXT,
    condition TEXT NOT NULL CHECK (condition IN ('NEW', 'GOOD', 'FAIR', 'DAMAGED', 'LOST')),
    circulation_status TEXT NOT NULL CHECK (circulation_status IN ('AVAILABLE', 'RESERVED', 'BORROWED', 'DAMAGED', 'LOST')),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (book_id) REFERENCES books(id)
);
CREATE INDEX idx_book_copies_book_id ON book_copies(book_id);
CREATE INDEX idx_book_copies_circulation_status ON book_copies(circulation_status);
