package catalogservice.controller;

import catalogservice.config.PublisherAuthGuard;
import catalogservice.dto.request.PublisherWriteRequest;
import catalogservice.dto.response.ApiResponse;
import catalogservice.dto.response.PageResponse;
import catalogservice.dto.response.PublisherResponse;
import catalogservice.service.Impl.PublisherService;
import jakarta.servlet.http.HttpServletRequest;
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
    private final PublisherAuthGuard authGuard;

    public PublisherController(PublisherService service, PublisherAuthGuard authGuard) {
        this.service = service;
        this.authGuard = authGuard;
    }

    @GetMapping
    public ApiResponse<PageResponse<PublisherResponse>> list(
        @RequestParam(required = false) String q,
        @RequestParam(required = false) String status,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        HttpServletRequest request) {
        authGuard.authorizeRead(request);
        return ApiResponse.ok(service.list(q, status, page, size), resolveTraceId(request));
    }

    @GetMapping("/{id}")
    public ApiResponse<PublisherResponse> get(@PathVariable String id, HttpServletRequest request) {
        authGuard.authorizeRead(request);
        return ApiResponse.ok(service.get(id), resolveTraceId(request));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<PublisherResponse>> create(@Valid @RequestBody PublisherWriteRequest request,
        HttpServletRequest servletRequest) {
        authGuard.authorizeStaffWrite(servletRequest);
        PublisherResponse publisher = service.create(request);
        return ResponseEntity.created(URI.create("/api/publishers/" + publisher.id()))
            .body(new ApiResponse<>(201, "Created", publisher, Instant.now(), resolveTraceId(servletRequest)));
    }

    @PutMapping("/{id}")
    public ApiResponse<PublisherResponse> update(@PathVariable String id, @Valid @RequestBody PublisherWriteRequest request,
        HttpServletRequest servletRequest) {
        authGuard.authorizeStaffWrite(servletRequest);
        return ApiResponse.ok(service.update(id, request), resolveTraceId(servletRequest));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id, HttpServletRequest request) {
        authGuard.authorizeStaffWrite(request);
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    public static String resolveTraceId(HttpServletRequest request) {
        String value = request.getHeader("X-Trace-Id");
        if (value == null || value.isBlank()) value = request.getHeader("X-Correlation-Id");
        return value != null && value.matches("[a-zA-Z0-9-]{1,64}") ? value : UUID.randomUUID().toString();
    }
}
