package customer.notificationservice.controller;

import customer.notificationservice.dto.NotificationDtos.ApiResponse;
import customer.notificationservice.dto.NotificationDtos.DeviceTokenRequest;
import customer.notificationservice.dto.NotificationDtos.DeviceTokenResponse;
import customer.notificationservice.dto.NotificationDtos.MarkAllReadResponse;
import customer.notificationservice.dto.NotificationDtos.NotificationQuery;
import customer.notificationservice.dto.NotificationDtos.NotificationResponse;
import customer.notificationservice.dto.NotificationDtos.PageResponse;
import customer.notificationservice.dto.NotificationDtos.UnreadCountResponse;
import customer.notificationservice.security.NotificationJwtAuthResolver;
import customer.notificationservice.service.DeviceTokenService;
import customer.notificationservice.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/notifications")
@Tag(name = "Notifications", description = "In-app notifications and FCM device tokens (MSS-038)")
public class NotificationController {
    private final NotificationService notificationService;
    private final DeviceTokenService deviceTokenService;
    private final NotificationJwtAuthResolver authResolver;

    public NotificationController(
            NotificationService notificationService,
            DeviceTokenService deviceTokenService,
            NotificationJwtAuthResolver authResolver
    ) {
        this.notificationService = notificationService;
        this.deviceTokenService = deviceTokenService;
        this.authResolver = authResolver;
    }

    @GetMapping
    @Operation(summary = "List authenticated user's in-app notifications")
    public ApiResponse<PageResponse<NotificationResponse>> listMine(
            @RequestParam(required = false) Boolean unreadOnly,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            HttpServletRequest request
    ) {
        var principal = authResolver.requireAuthenticated(request);
        var data = notificationService.listMine(principal.userId(), new NotificationQuery(unreadOnly, page, size));
        return ApiResponse.ok(data, resolveTraceId(request));
    }

    @GetMapping("/unread-count")
    @Operation(summary = "Get unread in-app notification count for authenticated user")
    public ApiResponse<UnreadCountResponse> unreadCount(HttpServletRequest request) {
        var principal = authResolver.requireAuthenticated(request);
        return ApiResponse.ok(notificationService.unreadCount(principal.userId()), resolveTraceId(request));
    }

    @PatchMapping("/{id}/read")
    @Operation(summary = "Mark a single notification as read (returns 404 if not owned by caller)")
    public ApiResponse<NotificationResponse> markRead(@PathVariable String id, HttpServletRequest request) {
        var principal = authResolver.requireAuthenticated(request);
        return ApiResponse.ok(notificationService.markRead(id, principal.userId()), resolveTraceId(request));
    }

    @PatchMapping("/read-all")
    @Operation(summary = "Mark all unread in-app notifications as read for authenticated user")
    public ApiResponse<MarkAllReadResponse> markAllRead(HttpServletRequest request) {
        var principal = authResolver.requireAuthenticated(request);
        return ApiResponse.ok(notificationService.markAllRead(principal.userId()), resolveTraceId(request));
    }

    @PostMapping("/device-tokens")
    @Operation(summary = "Register or refresh an FCM device token for authenticated user")
    public ResponseEntity<ApiResponse<DeviceTokenResponse>> registerDeviceToken(
            @Valid @RequestBody DeviceTokenRequest body,
            HttpServletRequest request
    ) {
        var principal = authResolver.requireAuthenticated(request);
        DeviceTokenResponse created = deviceTokenService.register(principal.userId(), body.token(), body.platform());
        return ResponseEntity.created(URI.create("/api/notifications/device-tokens/" + created.id()))
                .body(ApiResponse.created(created, resolveTraceId(request)));
    }

    @DeleteMapping("/device-tokens/{id}")
    @Operation(summary = "Deactivate/revoke an FCM device token owned by authenticated user")
    public ResponseEntity<Void> revokeDeviceToken(@PathVariable String id, HttpServletRequest request) {
        var principal = authResolver.requireAuthenticated(request);
        deviceTokenService.revoke(id, principal.userId());
        return ResponseEntity.noContent().build();
    }

    public static String resolveTraceId(HttpServletRequest request) {
        String trace = request.getHeader("X-Trace-Id");
        if (trace == null || trace.isBlank()) {
            trace = request.getHeader("X-Correlation-Id");
        }
        return (trace == null || trace.isBlank()) ? UUID.randomUUID().toString() : trace;
    }
}
