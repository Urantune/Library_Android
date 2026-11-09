package customer.reservationservice.controller;

import customer.reservationservice.dto.request.ReservationRequest;
import customer.reservationservice.dto.response.ReservationResponse;
import customer.reservationservice.dto.response.ResponseAPI;
import customer.reservationservice.service.ReservationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;

@FieldDefaults(level = lombok.AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
@RestController
@RequestMapping("/api/reservations")
public class ReservationController {
    ReservationService reservationService;

    @PostMapping
    public ResponseEntity<ResponseAPI<ReservationResponse>> requestReservation(
            @RequestHeader("X-User-Id") String userId,
            @Valid @RequestBody ReservationRequest request) {
        ReservationResponse result = reservationService.requestReservation(userId, request.bookId());
        return ResponseEntity.status(HttpStatus.CREATED).body(
                ResponseAPI.<ReservationResponse>builder()
                        .message("Book reservation request submitted")
                        .timestamp(Instant.now().toString())
                        .result(result)
                        .build());
    }
}
