package catalogservice.controller;

import catalogservice.config.PublisherAuthGuard;
import catalogservice.dto.response.ApiResponse;
import catalogservice.dto.response.BookResponse;
import catalogservice.dto.response.PageResponse;
import catalogservice.service.Impl.BookReadService;
import catalogservice.service.Impl.BookWriteService;
import catalogservice.dto.request.BookWriteRequest;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.time.Instant;
import org.springframework.http.ResponseEntity;
import java.net.URI;
import java.util.UUID;
import org.springframework.web.bind.annotation.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/books")
@Tag(name = "Books", description = "Catalog book management")
public class BookController {
    private final BookReadService service;
    private final BookWriteService writes;
    private final PublisherAuthGuard authGuard;

    public BookController(BookReadService service, BookWriteService writes,
        PublisherAuthGuard authGuard) {
        this.service = service;
        this.writes = writes;
        this.authGuard = authGuard;
    }

    @GetMapping
    @Operation(summary = "List active books", description = "Supports q, publisherId, authorId and categoryId filters with pagination.")
    public ApiResponse<PageResponse<BookResponse>> list(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String q,
        @RequestParam(required = false) String publisherId,
        @RequestParam(required = false) String authorId,
        @RequestParam(required = false) String categoryId,
        @RequestParam(required = false) String copyStatus,
        @RequestHeader(value = "X-Correlation-Id", required = false) String traceId,
        HttpServletRequest request
    ) {
        authGuard.authorizeRead(request);
        return ApiResponse.ok(service.list(page, size, q, publisherId, authorId, categoryId, copyStatus), trace(traceId));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a book by ID")
    public ApiResponse<BookResponse> detail(
        @PathVariable String id,
        @RequestHeader(value = "X-Correlation-Id", required = false) String traceId,
        HttpServletRequest request
    ) {
        authGuard.authorizeRead(request);
        return ApiResponse.ok(service.detail(id), trace(traceId));
    }

    static String trace(String value) {
        return value == null || value.isBlank() ? UUID.randomUUID().toString() : value;
    }

    @PostMapping
    @Operation(summary = "Create a book")
    public ResponseEntity<ApiResponse<BookResponse>> create(
        @Valid @RequestBody BookWriteRequest request,
        @RequestHeader(value = "X-Correlation-Id", required = false) String traceId,
        HttpServletRequest servletRequest
    ) {
        authGuard.authorizeBookWrite(servletRequest);
        var book = writes.create(request);
        return ResponseEntity.created(URI.create("/api/books/" + book.id()))
            .body(new ApiResponse<>(201, "Created", book, Instant.now(), trace(traceId)));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update book metadata")
    public ApiResponse<BookResponse> update(
        @PathVariable String id,
        @Valid @RequestBody BookWriteRequest request,
        @RequestHeader(value = "X-Correlation-Id", required = false) String traceId,
        HttpServletRequest servletRequest
    ) {
        authGuard.authorizeBookWrite(servletRequest);
        return ApiResponse.ok(writes.update(id, request), trace(traceId));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Soft-delete a book")
    public ResponseEntity<Void> delete(
        @PathVariable String id,
        HttpServletRequest request
    ) {
        authGuard.authorizeBookWrite(request);
        writes.deactivate(id);
        return ResponseEntity.noContent().build();
    }
}
