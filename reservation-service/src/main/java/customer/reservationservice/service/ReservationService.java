package customer.reservationservice.service;

import customer.reservationservice.dto.response.ReservationResponse;

public interface ReservationService {
    ReservationResponse requestReservation(String userId, String bookId);
}
