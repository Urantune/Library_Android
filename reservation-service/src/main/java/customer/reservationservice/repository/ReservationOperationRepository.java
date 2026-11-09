package customer.reservationservice.repository;

import customer.reservationservice.entity.ReservationOperationEntity;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReservationOperationRepository extends JpaRepository<ReservationOperationEntity, String> {
    Optional<ReservationOperationEntity> findFirstByReservationIdAndOperationTypeOrderByCreatedAtDesc(
            String reservationId,
            String operationType
    );

    List<ReservationOperationEntity> findByStatusOrderByUpdatedAtAsc(String status);
}
