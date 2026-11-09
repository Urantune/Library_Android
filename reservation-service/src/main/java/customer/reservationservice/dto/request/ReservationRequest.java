package customer.reservationservice.dto.request;

import jakarta.validation.constraints.NotBlank;

public record ReservationRequest(
        @NotBlank String bookId
) {
}
