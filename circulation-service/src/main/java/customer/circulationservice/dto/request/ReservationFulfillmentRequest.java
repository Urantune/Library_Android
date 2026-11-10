package customer.circulationservice.dto.request;

import jakarta.validation.constraints.NotBlank;

public record ReservationFulfillmentRequest(
        @NotBlank String loanId,
        @NotBlank String reservationId,
        @NotBlank String userId,
        @NotBlank String bookId,
        @NotBlank String copyId,
        @NotBlank String processedBy,
        @NotBlank String operationId
) {
}
