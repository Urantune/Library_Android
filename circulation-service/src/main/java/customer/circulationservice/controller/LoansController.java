package customer.circulationservice.controller;

import customer.circulationservice.dto.request.LoanRequestDTO;
import customer.circulationservice.dto.request.RejectLoanRequestDTO;
import customer.circulationservice.dto.response.LoanResponseDTO;
import customer.circulationservice.dto.response.PageDTO;
import customer.circulationservice.dto.response.ResponseAPI;
import customer.circulationservice.exception.AppException;
import customer.circulationservice.exception.ErrorCode;
import customer.circulationservice.service.ILoansService;
import jakarta.validation.Valid;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;

@FieldDefaults(level = lombok.AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
@RestController
@RequestMapping("/api/loans")
public class LoansController {
    ILoansService loansService;

    @PostMapping("/admin/{loanId}/reject")
    public ResponseEntity<ResponseAPI<LoanResponseDTO>> rejectLoan(
            @PathVariable String loanId,
            @RequestBody(required = false) @Valid RejectLoanRequestDTO request,
            @RequestHeader(value = "X-User-Id", required = false) String adminUserId,
            @RequestHeader(value = "X-User-Roles", required = false) String currentUserRoles) {
        verifyAdmin(currentUserRoles);
        String reason = request == null ? null : request.getReason();
        LoanResponseDTO result = loansService.rejectLoan(loanId, adminUserId, reason);
        return ResponseEntity.ok(
                ResponseAPI.<LoanResponseDTO>builder()
                        .message("Loan request rejected")
                        .timestamp(Instant.now().toString())
                        .result(result)
                        .build());
    }

    @PostMapping("/admin/{loanId}/approve")
    public ResponseEntity<ResponseAPI<LoanResponseDTO>> approveLoan(
            @PathVariable String loanId,
            @RequestHeader(value = "X-User-Id", required = false) String adminUserId,
            @RequestHeader(value = "X-User-Roles", required = false) String currentUserRoles) {
        verifyAdmin(currentUserRoles);
        LoanResponseDTO result = loansService.approveLoan(loanId, adminUserId);
        return ResponseEntity.ok(
                ResponseAPI.<LoanResponseDTO>builder()
                        .message("Loan approved and marked as borrowed")
                        .timestamp(Instant.now().toString())
                        .result(result)
                        .build());
    }



    @GetMapping("/admin")
    public ResponseEntity<ResponseAPI<PageDTO<LoanResponseDTO>>> getAllLoans(
            @RequestHeader(value = "X-User-Roles", required = false) String currentUserRoles,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        verifyAdmin(currentUserRoles);
        validatePage(page, size);
        PageDTO<LoanResponseDTO> result = loansService.getAllLoans(page, size);
        return ResponseEntity.ok(
                ResponseAPI.<PageDTO<LoanResponseDTO>>builder()
                        .message("All loans")
                        .timestamp(Instant.now().toString())
                        .result(result)
                        .build());
    }

    @GetMapping("/users/{userId}/borrowed")
    public ResponseEntity<ResponseAPI<PageDTO<LoanResponseDTO>>> getBorrowedLoans(
            @PathVariable String userId,
            @RequestHeader("X-User-Id") String currentUserId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        verifyOwner(userId, currentUserId);
        validatePage(page, size);
        PageDTO<LoanResponseDTO> result = loansService.getBorrowedLoans(userId, page, size);
        return ResponseEntity.ok(
                ResponseAPI.<PageDTO<LoanResponseDTO>>builder()
                        .message("Current borrowed books")
                        .timestamp(Instant.now().toString())
                        .result(result)
                        .build());
    }

    @GetMapping("/users/{userId}/requested")
    public ResponseEntity<ResponseAPI<PageDTO<LoanResponseDTO>>> getRequestedLoans(
            @PathVariable String userId,
            @RequestHeader("X-User-Id") String currentUserId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        verifyOwner(userId, currentUserId);
        validatePage(page, size);
        PageDTO<LoanResponseDTO> result = loansService.getRequestedLoans(userId, page, size);
        return ResponseEntity.ok(
                ResponseAPI.<PageDTO<LoanResponseDTO>>builder()
                        .message("Requested loans")
                        .timestamp(Instant.now().toString())
                        .result(result)
                        .build());
    }

    @PostMapping
    public ResponseEntity<ResponseAPI<LoanResponseDTO>> requestLoan(
            @Valid @RequestBody LoanRequestDTO request) {
        LoanResponseDTO result = loansService.requestLoan(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(
                ResponseAPI.<LoanResponseDTO>builder()
                        .message("Loan request submitted")
                        .timestamp(Instant.now().toString())
                        .result(result)
                        .build());
    }

    @GetMapping("/users/{userId}/history")
    public ResponseEntity<ResponseAPI<PageDTO<LoanResponseDTO>>> getLoanHistory(
            @PathVariable String userId,
            @RequestHeader("X-User-Id") String currentUserId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        verifyOwner(userId, currentUserId);
        validatePage(page, size);
        PageDTO<LoanResponseDTO> result = loansService.getLoanHistory(userId, page, size);
        return ResponseEntity.ok(
                ResponseAPI.<PageDTO<LoanResponseDTO>>builder()
                        .message("Loan history")
                        .timestamp(Instant.now().toString())
                        .result(result)
                        .build());
    }

    private void verifyOwner(String userId, String currentUserId) {
        if (!userId.equals(currentUserId)) {
            throw new AppException(ErrorCode.LOAN_ACCESS_DENIED);
        }
    }

    private void verifyAdmin(String currentUserRoles) {
        boolean isAdmin = currentUserRoles != null && Arrays.stream(currentUserRoles.split(","))
                .map(String::trim)
                .anyMatch("ADMIN"::equals);
        if (!isAdmin) {
            throw new AppException(ErrorCode.ADMIN_ACCESS_DENIED);
        }
    }

    private void validatePage(int page, int size) {
        if (page < 0 || size < 1 || size > 100) {
            throw new AppException(ErrorCode.BAD_REQUEST);
        }
    }
}
