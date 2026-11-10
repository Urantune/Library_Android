package catalogservice.controller;

import catalogservice.dto.request.CopyClaimRequest;
import catalogservice.dto.request.CopyReleaseRequest;
import catalogservice.dto.request.CopyTransferRequest;
import catalogservice.service.CopyInventoryService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/internal/copies")
public class CopyInventoryController {
    private final CopyInventoryService inventory;
    private final byte[] internalToken;

    public CopyInventoryController(
            CopyInventoryService inventory,
            @Value("${app.clients.internal-token:dev-internal-service-token}") String internalToken
    ) {
        if (internalToken == null || internalToken.isBlank()) {
            throw new IllegalArgumentException("INTERNAL_SERVICE_TOKEN must not be blank");
        }
        this.inventory = inventory;
        this.internalToken = internalToken.getBytes(StandardCharsets.UTF_8);
    }

    @PostMapping("/{copyId}/claim")
    public void claim(
            @PathVariable String copyId,
            @Valid @RequestBody CopyClaimRequest body,
            HttpServletRequest request
    ) {
        authorize(request);
        inventory.claim(body.bookId(), copyId, body.holderType(), body.holderId(), body.operationId());
    }

    @PostMapping("/{copyId}/release")
    public void release(
            @PathVariable String copyId,
            @Valid @RequestBody CopyReleaseRequest body,
            HttpServletRequest request
    ) {
        authorize(request);
        inventory.release(copyId, body.expectedHolderId(), body.operationId(), body.reason(), trace(request));
    }

    @PostMapping("/{copyId}/transfer-holder")
    public void transfer(
            @PathVariable String copyId,
            @Valid @RequestBody CopyTransferRequest body,
            HttpServletRequest request
    ) {
        authorize(request);
        inventory.transfer(copyId, body.expectedHolderId(), body.newHolderType(), body.newHolderId(), body.operationId());
    }

    private void authorize(HttpServletRequest request) {
        String provided = request.getHeader("X-Internal-Token");
        if (provided == null || provided.isBlank()
                || !MessageDigest.isEqual(internalToken, provided.getBytes(StandardCharsets.UTF_8))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid internal service token");
        }
    }

    private static String trace(HttpServletRequest request) {
        String trace = request.getHeader("X-Trace-Id");
        if (trace == null || trace.isBlank()) trace = request.getHeader("X-Correlation-Id");
        return trace;
    }
}
