package customer.catalogservice.book.service;

import customer.catalogservice.book.dto.BookResponse;
import customer.catalogservice.book.dto.BookWriteRequest;
import customer.catalogservice.book.mapper.BookMapper;
import customer.catalogservice.entity.Book;
import customer.catalogservice.entity.BookStatus;
import customer.catalogservice.repository.*;
import java.time.Year;
import java.time.ZoneOffset;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class BookWriteService {
    private final BookRepository books;
    private final AuthorRepository authors;
    private final CategoryRepository categories;
    private final PublisherRepository publishers;
    private final BookMapper mapper;

    public BookWriteService(BookRepository books, AuthorRepository authors,
        CategoryRepository categories, PublisherRepository publishers, BookMapper mapper) {
        this.books = books;
        this.authors = authors;
        this.categories = categories;
        this.publishers = publishers;
        this.mapper = mapper;
    }

    @Transactional
    public BookResponse create(BookWriteRequest request) {
        Book book = new Book();
        apply(request, book);
        return mapper.toResponse(books.saveAndFlush(book));
    }

    @Transactional
    public BookResponse update(String id, BookWriteRequest request) {
        Book book = requireBook(id);
        apply(request, book);
        return mapper.toResponse(books.saveAndFlush(book));
    }

    @Transactional
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
        var publisher = request.publisherId() == null || request.publisherId().isBlank()
            ? null : publishers.findById(request.publisherId())
                .orElseThrow(() -> invalid("publisherId", "Publisher does not exist"));
        var authorIds = ids(request.authorIds());
        var authorEntities = authors.findAllById(authorIds);
        if (authorEntities.size() != authorIds.size()) throw invalid("authorIds", "Author does not exist");
        var categoryIds = ids(request.categoryIds());
        var categoryEntities = categories.findAllById(categoryIds);
        if (categoryEntities.size() != categoryIds.size()) throw invalid("categoryIds", "Category does not exist");
        book.setTitle(request.title().trim());
        book.setIsbn(isbn);
        book.setDescription(request.description());
        book.setPublicationYear(request.publicationYear());
        book.setLanguage(request.language());
        book.setPageCount(request.pageCount());
        book.setCoverUrl(request.coverUrl());
        book.setStatus(status);
        book.setPublisher(publisher);
        book.getAuthors().clear();
        book.getAuthors().addAll(authorEntities);
        book.getCategories().clear();
        book.getCategories().addAll(categoryEntities);
    }

    private Set<String> ids(List<String> values) {
        return values == null ? Set.of() : new LinkedHashSet<>(values);
    }

    private BookWriteException invalid(String field, String message) {
        return new BookWriteException(HttpStatus.BAD_REQUEST, "INVALID_BOOK", field, message);
    }
}
