package customer.circulationservice.controller;

import customer.circulationservice.dto.request.LoanRenewalRequestDTO;
import customer.circulationservice.dto.response.LoanRenewalResponseDTO;
import customer.circulationservice.dto.response.ResponseAPI;
import customer.circulationservice.service.ILoanRenewals;
import jakarta.validation.Valid;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@FieldDefaults(level = lombok.AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
@RestController
@RequestMapping("/api/loan-renewals")
public class LoanRenewalsController {
    ILoanRenewals renewalService;

    @PostMapping
    public ResponseEntity<ResponseAPI<LoanRenewalResponseDTO>> requestRenewal(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody LoanRenewalRequestDTO request) {
        LoanRenewalResponseDTO result = renewalService.requestRenewal(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(
                ResponseAPI.<LoanRenewalResponseDTO>builder()
                        .message("Renewal request submitted")
                        .timestamp(Instant.now().toString())
                        .result(result)
                        .build());
    }
}
