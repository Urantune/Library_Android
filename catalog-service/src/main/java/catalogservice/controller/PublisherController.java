package catalogservice.controller;

import catalogservice.dto.request.PublisherWriteRequest;
import catalogservice.dto.response.ApiResponse;
import catalogservice.dto.response.PageResponse;
import catalogservice.dto.response.PublisherResponse;
import catalogservice.service.Impl.PublisherService;
import jakarta.validation.Valid;
import java.net.URI;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/publishers")
public class PublisherController {
    private final PublisherService service;

    public PublisherController(PublisherService service) { this.service = service; }

    @GetMapping
    public ApiResponse<PageResponse<PublisherResponse>> list(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestHeader(value = "X-Correlation-Id", required = false) String traceId) {
        return ApiResponse.ok(service.list(page, size), trace(traceId));
    }

    @GetMapping("/{id}")
    public ApiResponse<PublisherResponse> get(@PathVariable String id,
        @RequestHeader(value = "X-Correlation-Id", required = false) String traceId) {
        return ApiResponse.ok(service.get(id), trace(traceId));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<PublisherResponse>> create(@Valid @RequestBody PublisherWriteRequest request,
        @RequestHeader(value = "X-Correlation-Id", required = false) String traceId) {
        PublisherResponse publisher = service.create(request);
        return ResponseEntity.created(URI.create("/api/publishers/" + publisher.id()))
            .body(new ApiResponse<>(201, "Created", publisher, Instant.now(), trace(traceId)));
    }

    @PutMapping("/{id}")
    public ApiResponse<PublisherResponse> update(@PathVariable String id, @Valid @RequestBody PublisherWriteRequest request,
        @RequestHeader(value = "X-Correlation-Id", required = false) String traceId) {
        return ApiResponse.ok(service.update(id, request), trace(traceId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    private String trace(String value) { return value == null || value.isBlank() ? UUID.randomUUID().toString() : value; }
}
