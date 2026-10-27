package catalogservice.service.Impl;

import catalogservice.dto.response.BookResponse;
import catalogservice.dto.response.PageResponse;
import catalogservice.mapper.BookMapper;
import catalogservice.repository.BookRepository;
import catalogservice.repository.BookSpecifications;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
@Transactional(readOnly = true)
public class BookReadService {
    private final BookRepository books;
    private final BookMapper mapper;

    public BookReadService(BookRepository books, BookMapper mapper) {
        this.books = books;
        this.mapper = mapper;
    }

    @Cacheable(cacheNames = "book-pages", key = "#page + ':' + #size + ':' + #q + ':' + #publisherId + ':' + #authorId + ':' + #categoryId")
    public PageResponse<BookResponse> list(int page, int size, String q, String publisherId, String authorId, String categoryId) {
        if (page < 0 || size < 1 || size > 100) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Page must be >= 0 and size between 1 and 100");
        }
        var result = books.findAll(BookSpecifications.activeSearch(q, publisherId, authorId, categoryId),
            PageRequest.of(page, size, Sort.by("title").ascending().and(Sort.by("id"))));
        return new PageResponse<>(result.getContent().stream().map(mapper::toResponse).toList(),
            page, size, result.getTotalElements(), result.getTotalPages());
    }

    @Cacheable(cacheNames = "book-details", key = "#id")
    public BookResponse detail(String id) {
        var book = books.findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Book not found"));
        return mapper.toResponse(book);
    }
}
