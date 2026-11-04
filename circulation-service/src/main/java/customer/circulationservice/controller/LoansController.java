package customer.circulationservice.controller;

import customer.circulationservice.dto.request.LoanRequestDTO;
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
import org.springframework.web.bind.annotation.RestController;

@FieldDefaults(level = lombok.AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
@RestController
@RequestMapping("/api/loans")
public class LoansController {
    ILoansService loansService;

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

    @GetMapping("/users/{userId}/borrowed")
    public ResponseEntity<ResponseAPI<PageDTO<LoanResponseDTO>>> getBorrowedLoans(
            @PathVariable String userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        if (page < 0 || size < 1 || size > 100) {
            throw new AppException(ErrorCode.BAD_REQUEST);
        }
        PageDTO<LoanResponseDTO> result = loansService.getBorrowedLoans(userId, page, size);
        return ResponseEntity.ok(
                ResponseAPI.<PageDTO<LoanResponseDTO>>builder()
                        .message("Current borrowed books")
                        .timestamp(Instant.now().toString())
                        .result(result)
                        .build());
    }
}
