package customer.reservationservice.service.impl;

import customer.reservationservice.dto.response.ReservationResponse;
import customer.reservationservice.entity.Reservation;
import customer.reservationservice.exception.AppException;
import customer.reservationservice.exception.ErrorCode;
import customer.reservationservice.mapper.ReservationMapper;
import customer.reservationservice.repository.ReservationRepository;
import customer.reservationservice.service.ReservationService;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@FieldDefaults(level = lombok.AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
public class ReservationImpl implements ReservationService {
    ReservationRepository reservationRepository;
    ReservationMapper reservationMapper;

    @Override
    @Transactional
    public ReservationResponse requestReservation(String userId, String bookId) {
        if (userId == null || userId.isBlank() || bookId == null || bookId.isBlank()) {
            throw new AppException(ErrorCode.BAD_REQUEST);
        }

        if (reservationRepository.existsByUserIdAndBookIdAndStatusIn(
                userId, bookId, List.of("WAITING", "READY"))) {
            throw new AppException(ErrorCode.DUPLICATE_RESERVATION);
        }

        int queueNo = reservationRepository.findFirstByBookIdOrderByQueueNoDesc(bookId)
                .map(reservation -> reservation.getQueueNo() + 1)
                .orElse(1);
        Reservation reservation = new Reservation(
                UUID.randomUUID().toString(),
                userId,
                bookId,
                "WAITING",
                queueNo,
                Instant.now().toString());

        return reservationMapper.toResponse(reservationRepository.save(reservation));
    }
}
