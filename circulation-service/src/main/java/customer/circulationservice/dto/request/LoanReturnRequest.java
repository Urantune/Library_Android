package customer.circulationservice.dto.request;

import jakarta.validation.constraints.NotBlank;

public record LoanReturnRequest(
        @NotBlank String copyId,
        @NotBlank String condition,
        @NotBlank String operationId
) {
}
