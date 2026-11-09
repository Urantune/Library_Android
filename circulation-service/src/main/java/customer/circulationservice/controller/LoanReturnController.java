package customer.circulationservice.controller;

import customer.circulationservice.dto.request.LoanReturnRequest;
import customer.circulationservice.service.impl.LoanReturnService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/internal/loans")
public class LoanReturnController {
    private final LoanReturnService returns;
    private final byte[] internalToken;

    public LoanReturnController(
            LoanReturnService returns,
            @Value("${app.clients.internal-token:dev-internal-service-token}") String internalToken
    ) {
        if (internalToken == null || internalToken.isBlank()) {
            throw new IllegalArgumentException("INTERNAL_SERVICE_TOKEN must not be blank");
        }
        this.returns = returns;
        this.internalToken = internalToken.getBytes(StandardCharsets.UTF_8);
    }

    @PostMapping("/{loanId}/return")
    public void returnCopy(
            @PathVariable String loanId,
            @Valid @RequestBody LoanReturnRequest body,
            @RequestHeader("X-Internal-Token") String token,
            HttpServletRequest request
    ) {
        if (token == null || token.isBlank()
                || !MessageDigest.isEqual(internalToken, token.getBytes(StandardCharsets.UTF_8))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid internal service token");
        }
        String trace = request.getHeader("X-Trace-Id");
        if (trace == null || trace.isBlank()) trace = request.getHeader("X-Correlation-Id");
        returns.returnCopy(loanId, body, trace);
    }
}
