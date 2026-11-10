package customer.reservationservice.client;

import customer.reservationservice.dto.ReservationDtos.BookAvailability;
import customer.reservationservice.dto.ReservationDtos.ClaimOutcome;

public interface CatalogInventoryClient {
    BookAvailability getAvailability(String bookId, String traceId);

    ClaimOutcome claimCopyForReservation(String bookId, String copyId, String reservationId, String operationId, String traceId);

    void releaseCopy(String copyId, String expectedHolderId, String operationId, String reason, String traceId);

    void transferCopyHolder(
            String copyId,
            String expectedHolderId,
            String newHolderType,
            String newHolderId,
            String operationId,
            String traceId
    );
}
