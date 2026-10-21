package customer.catalogservice.book.controller;

import customer.catalogservice.book.dto.ApiResponse;
import customer.catalogservice.book.dto.BookResponse;
import customer.catalogservice.book.dto.PageResponse;
import customer.catalogservice.book.service.BookReadService;
import java.util.UUID;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/books")
public class BookController {
    private final BookReadService service;

    public BookController(BookReadService service) {
        this.service = service;
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
}
