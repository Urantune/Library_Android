package catalogservice.controller;

import catalogservice.config.PublisherAuthGuard;
import catalogservice.dto.request.BookCopyInput;
import catalogservice.dto.response.ApiResponse;
import catalogservice.dto.response.BookCopyResponse;
import catalogservice.service.BookCopyService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/books/{bookId}/copies")
public class BookCopyController {
    private final BookCopyService copies;
    private final PublisherAuthGuard auth;

    public BookCopyController(BookCopyService copies, PublisherAuthGuard auth) {
        this.copies = copies;
        this.auth = auth;
    }

    @GetMapping
    public ApiResponse<List<BookCopyResponse>> list(@PathVariable String bookId, HttpServletRequest request) {
        auth.authorizeRead(request);
        return ApiResponse.ok(copies.list(bookId), BookController.trace(request.getHeader("X-Correlation-Id")));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<BookCopyResponse> create(@PathVariable String bookId, @Valid @RequestBody BookCopyInput input, HttpServletRequest request) {
        auth.authorizeBookWrite(request);
        String trace = BookController.trace(request.getHeader("X-Correlation-Id"));
        return new ApiResponse<>(201, "Created", copies.create(bookId, input, trace), Instant.now(), trace);
    }

    @PatchMapping("/{copyId}/status")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void status(@PathVariable String bookId, @PathVariable String copyId, @RequestBody Map<String, String> input, HttpServletRequest request) {
        auth.authorizeBookWrite(request);
        copies.updateStatus(bookId, copyId, input.getOrDefault("status", ""), request.getHeader("X-Correlation-Id"));
    }
}
