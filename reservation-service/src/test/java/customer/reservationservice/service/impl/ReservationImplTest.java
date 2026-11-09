package customer.reservationservice.service.impl;

import customer.reservationservice.dto.response.ReservationResponse;
import customer.reservationservice.entity.Reservation;
import customer.reservationservice.exception.AppException;
import customer.reservationservice.exception.ErrorCode;
import customer.reservationservice.mapper.ReservationMapper;
import customer.reservationservice.repository.ReservationRepository;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReservationImplTest {
    @Mock
    private ReservationRepository reservationRepository;

    @Mock
    private ReservationMapper reservationMapper;

    @InjectMocks
    private ReservationImpl reservationService;

    @Test
    void createsWaitingReservationAtNextQueuePosition() {
        when(reservationRepository.existsByUserIdAndBookIdAndStatusIn(
                "user-1", "book-1", List.of("WAITING", "READY"))).thenReturn(false);
        when(reservationRepository.findFirstByBookIdOrderByQueueNoDesc("book-1"))
                .thenReturn(Optional.of(new Reservation("old", "other", "book-1", "WAITING", 3, "then")));
        when(reservationRepository.save(any(Reservation.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(reservationMapper.toResponse(any(Reservation.class))).thenAnswer(invocation -> {
            Reservation saved = invocation.getArgument(0);
            return new ReservationResponse(saved.getId(), saved.getUserId(), saved.getBookId(), saved.getStatus(),
                    saved.getQueueNo(), saved.getCreatedAt(), saved.getReadyAt(), saved.getExpiresAt(),
                    saved.getFulfilledAt(), saved.getCancelledAt());
        });

        ReservationResponse result = reservationService.requestReservation("user-1", "book-1");

        assertEquals("user-1", result.userId());
        assertEquals("book-1", result.bookId());
        assertEquals("WAITING", result.status());
        assertEquals(4, result.queueNo());
        assertNotNull(result.id());
        assertNotNull(result.createdAt());
    }

    @Test
    void rejectsAnotherActiveReservationForSameUserAndBook() {
        when(reservationRepository.existsByUserIdAndBookIdAndStatusIn(
                "user-1", "book-1", List.of("WAITING", "READY"))).thenReturn(true);

        AppException exception = assertThrows(AppException.class,
                () -> reservationService.requestReservation("user-1", "book-1"));

        assertEquals(ErrorCode.DUPLICATE_RESERVATION, exception.getErrorCode());
        verify(reservationRepository, never()).save(any(Reservation.class));
    }

    @Test
    void rejectsBlankBookId() {
        AppException exception = assertThrows(AppException.class,
                () -> reservationService.requestReservation("user-1", " "));

        assertEquals(ErrorCode.BAD_REQUEST, exception.getErrorCode());
        verify(reservationRepository, never()).save(any(Reservation.class));
    }
}
