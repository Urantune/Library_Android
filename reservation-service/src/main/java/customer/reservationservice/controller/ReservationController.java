package customer.reservationservice.controller;

import customer.reservationservice.dto.ReservationDtos.ApiResponse;
import customer.reservationservice.dto.ReservationDtos.CreateReservationRequest;
import customer.reservationservice.dto.ReservationDtos.PageResponse;
import customer.reservationservice.dto.ReservationDtos.ReservationQuery;
import customer.reservationservice.dto.ReservationDtos.ReservationResponse;
import customer.reservationservice.security.ReservationJwtAuthResolver;
import customer.reservationservice.service.ReservationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/reservations")
@Tag(name = "Reservations", description = "Book reservation queue management (MSS-037)")
public class ReservationController {
    private final ReservationService reservationService;
    private final ReservationJwtAuthResolver authResolver;

    public ReservationController(
            ReservationService reservationService,
            ReservationJwtAuthResolver authResolver
    ) {
        this.reservationService = reservationService;
        this.authResolver = authResolver;
    }

    @PostMapping
    @Operation(summary = "Place a reservation when a book has zero available copies")
    public ResponseEntity<ApiResponse<ReservationResponse>> create(
            @Valid @RequestBody CreateReservationRequest body,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            HttpServletRequest request
    ) {
        var principal = authResolver.requireAuthenticated(request);
        String traceId = resolveTraceId(request);
        ReservationResponse created = reservationService.create(
                principal.userId(),
                body.bookId(),
                idempotencyKey,
                traceId
        );
        return ResponseEntity.created(URI.create("/api/reservations/" + created.id()))
                .body(ApiResponse.created(created, traceId));
    }

    @GetMapping("/me")
    @Operation(summary = "List authenticated user's reservations with dynamic queue positions")
    public ApiResponse<PageResponse<ReservationResponse>> listMine(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            HttpServletRequest request
    ) {
        var principal = authResolver.requireAuthenticated(request);
        var data = reservationService.listMine(principal.userId(), new ReservationQuery(status, page, size));
        return ApiResponse.ok(data, resolveTraceId(request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Cancel authenticated user's active reservation")
    public ResponseEntity<Void> cancel(@PathVariable String id, HttpServletRequest request) {
        var principal = authResolver.requireAuthenticated(request);
        reservationService.cancel(id, principal.userId(), resolveTraceId(request));
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/fulfill")
    @Operation(summary = "Staff action: fulfill a READY reservation into a committed Circulation loan")
    public ApiResponse<ReservationResponse> fulfill(
            @PathVariable String id,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            HttpServletRequest request
    ) {
        var staff = authResolver.requireStaff(request);
        String traceId = resolveTraceId(request);
        ReservationResponse fulfilled = reservationService.fulfill(id, staff.userId(), idempotencyKey, traceId);
        return ApiResponse.ok(fulfilled, traceId);
    }

    public static String resolveTraceId(HttpServletRequest request) {
        String trace = request.getHeader("X-Trace-Id");
        if (trace == null || trace.isBlank()) {
            trace = request.getHeader("X-Correlation-Id");
        }
        return (trace == null || trace.isBlank()) ? UUID.randomUUID().toString() : trace;
    }
}
