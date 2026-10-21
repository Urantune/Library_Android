package customer.catalogservice.book.controller;

import customer.catalogservice.book.dto.ApiResponse;
import customer.catalogservice.book.dto.BookResponse;
import customer.catalogservice.book.dto.PageResponse;
import customer.catalogservice.book.service.BookReadService;
import customer.catalogservice.book.service.BookWriteService;
import customer.catalogservice.book.dto.BookWriteRequest;
import jakarta.validation.Valid;
import java.time.Instant;
import org.springframework.http.ResponseEntity;
import java.net.URI;
import java.util.UUID;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/books")
public class BookController {
    private final BookReadService service;
    private final BookWriteService writes;

    public BookController(BookReadService service, BookWriteService writes) {
        this.service = service;
        this.writes = writes;
    }

    @GetMapping
    public ApiResponse<PageResponse<BookResponse>> list(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestHeader(value = "X-Correlation-Id", required = false) String traceId
    ) {
        return ApiResponse.ok(service.list(page, size), trace(traceId));
    }

    @GetMapping("/{id}")
    public ApiResponse<BookResponse> detail(
        @PathVariable String id,
        @RequestHeader(value = "X-Correlation-Id", required = false) String traceId
    ) {
        return ApiResponse.ok(service.detail(id), trace(traceId));
    }

    static String trace(String value) {
        return value == null || value.isBlank() ? UUID.randomUUID().toString() : value;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<BookResponse>> create(@Valid @RequestBody BookWriteRequest request,
        @RequestHeader(value = "X-Correlation-Id", required = false) String traceId) {
        var book = writes.create(request);
        return ResponseEntity.created(URI.create("/api/books/" + book.id()))
            .body(new ApiResponse<>(201, "Created", book, Instant.now(), trace(traceId)));
    }

    @PutMapping("/{id}")
    public ApiResponse<BookResponse> update(@PathVariable String id, @Valid @RequestBody BookWriteRequest request,
        @RequestHeader(value = "X-Correlation-Id", required = false) String traceId) {
        return ApiResponse.ok(writes.update(id, request), trace(traceId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        writes.deactivate(id);
        return ResponseEntity.noContent().build();
    }
}
