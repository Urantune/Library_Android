package customer.reservationservice.client;

import customer.reservationservice.dto.ReservationDtos.FulfilledLoanResult;

public interface CirculationLoanClient {
    FulfilledLoanResult fulfillReservationIntoLoan(
            String targetLoanId,
            String reservationId,
            String userId,
            String bookId,
            String copyId,
            String actorId,
            String operationId,
            String idempotencyKey,
            String traceId
    );
}
