package customer.circulationservice.controller;

import customer.circulationservice.dto.request.LoanRenewalRequestDTO;
import customer.circulationservice.dto.response.LoanRenewalResponseDTO;
import customer.circulationservice.dto.response.ResponseAPI;
import customer.circulationservice.service.ILoanRenewals;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.List;

import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@FieldDefaults(level = lombok.AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
@RestController
@RequestMapping("/api/loan-renewals")
public class LoanRenewalsController {
    ILoanRenewals renewalService;

    @GetMapping
    public ResponseEntity<ResponseAPI<List<LoanRenewalResponseDTO>>> getRenewals() {
        List<LoanRenewalResponseDTO> result = renewalService.getRenewal();
        return ResponseEntity.ok(
                ResponseAPI.<List<LoanRenewalResponseDTO>>builder()
                        .message("Renewal requests")
                        .timestamp(Instant.now().toString())
                        .result(result)
                        .build()
        );
    }

    @PostMapping("/admin/{renewalId}/approve")
    public ResponseEntity<ResponseAPI<LoanRenewalResponseDTO>> approveRenewal(
            @PathVariable String renewalId,
            @RequestHeader("X-User-Id") String adminUserId) {

        LoanRenewalResponseDTO result =
                renewalService.approveRenewal(renewalId, adminUserId);

        return ResponseEntity.ok(
                ResponseAPI.<LoanRenewalResponseDTO>builder()
                        .message("Renewal request approved")
                        .timestamp(Instant.now().toString())
                        .result(result)
                        .build());
    }

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
