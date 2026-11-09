package customer.reservationservice.dto.response;

public record ReservationResponse(
        String id,
        String userId,
        String bookId,
        String status,
        Integer queueNo,
        String createdAt,
        String readyAt,
        String expiresAt,
        String fulfilledAt,
        String cancelledAt
) {
}
