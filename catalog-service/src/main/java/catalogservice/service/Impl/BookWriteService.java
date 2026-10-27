package catalogservice.service.Impl;

import catalogservice.dto.response.BookResponse;
import catalogservice.dto.request.BookWriteRequest;
import catalogservice.mapper.BookMapper;
import catalogservice.entity.Book;
import catalogservice.enums.BookStatus;
import catalogservice.repository.BookRepository;
import java.time.Year;
import java.time.ZoneOffset;

import catalogservice.exception.BookWriteException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Caching;
import org.springframework.web.server.ResponseStatusException;

@Service
public class BookWriteService {
    private final BookRepository books;
    private final BookMapper mapper;

    public BookWriteService(BookRepository books, BookMapper mapper) {
        this.books = books;
        this.mapper = mapper;
    }

    @Transactional
    @CacheEvict(cacheNames = "book-pages", allEntries = true)
    public BookResponse create(BookWriteRequest request) {
        Book book = new Book();
        apply(request, book);
        return mapper.toResponse(books.saveAndFlush(book));
    }

    @Transactional
    @Caching(evict = {@CacheEvict(cacheNames = "book-pages", allEntries = true), @CacheEvict(cacheNames = "book-details", key = "#id")})
    public BookResponse update(String id, BookWriteRequest request) {
        Book book = requireBook(id);
        apply(request, book);
        return mapper.toResponse(books.saveAndFlush(book));
    }

    @Transactional
    @Caching(evict = {@CacheEvict(cacheNames = "book-pages", allEntries = true), @CacheEvict(cacheNames = "book-details", key = "#id")})
    public void deactivate(String id) {
        Book book = requireBook(id);
        book.setStatus(BookStatus.INACTIVE);
        books.saveAndFlush(book);
    }

    private Book requireBook(String id) {
        return books.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Book not found"));
    }

    private void apply(BookWriteRequest request, Book book) {
        if ((request.publisherId() != null && !request.publisherId().isBlank())
            || (request.authorIds() != null && !request.authorIds().isEmpty())
            || (request.categoryIds() != null && !request.categoryIds().isEmpty())) {
            throw new BookWriteException(HttpStatus.CONFLICT, "RELATION_NOT_READY", "relations",
                "Related modules are not ready; use null or empty references");
        }
        String isbn = request.isbn().replaceAll("[\\s-]", "").toUpperCase(java.util.Locale.ROOT);
        if (isbn.isBlank()) throw invalid("isbn", "ISBN is required");
        books.findByIsbn(isbn).ifPresent(existing -> {
            if (!existing.getId().equals(book.getId())) {
                throw new BookWriteException(HttpStatus.CONFLICT, "DUPLICATE_ISBN", "isbn", "ISBN already exists");
            }
        });
        if (request.publicationYear() != null && request.publicationYear() > Year.now(ZoneOffset.UTC).getValue() + 1) {
            throw invalid("publicationYear", "Publication year cannot be in the future");
        }
        BookStatus status;
        try {
            status = request.status() == null ? BookStatus.ACTIVE : BookStatus.valueOf(request.status());
        } catch (IllegalArgumentException ex) {
            throw invalid("status", "Status must be ACTIVE or INACTIVE");
        }
        book.setTitle(request.title().trim());
        book.setIsbn(isbn);
        book.setDescription(request.description());
        book.setPublicationYear(request.publicationYear());
        book.setLanguage(request.language());
        book.setPageCount(request.pageCount());
        book.setCoverUrl(request.coverUrl());
        book.setStatus(status);
    }

    private BookWriteException invalid(String field, String message) {
        return new BookWriteException(HttpStatus.BAD_REQUEST, "INVALID_BOOK", field, message);
    }
}
