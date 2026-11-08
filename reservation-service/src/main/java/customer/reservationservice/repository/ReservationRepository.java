package customer.reservationservice.repository;

import customer.reservationservice.entity.Reservation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.Optional;

@Repository
public interface ReservationRepository extends JpaRepository<Reservation,String> {
    boolean existsByUserIdAndBookIdAndStatusIn(String userId, String bookId, Collection<String> statuses);

    Optional<Reservation> findFirstByBookIdOrderByQueueNoDesc(String bookId);
}
