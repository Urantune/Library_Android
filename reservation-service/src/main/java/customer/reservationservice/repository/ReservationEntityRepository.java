package customer.reservationservice.repository;

import customer.reservationservice.entity.ReservationEntity;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Repository queries for the reservation queue and fulfillment workflow. */
public interface ReservationEntityRepository extends JpaRepository<ReservationEntity, String> {
    boolean existsByUserIdAndBookIdAndStatusIn(String userId, String bookId, List<String> statuses);

    boolean existsByHeldCopyIdAndStatus(String heldCopyId, String status);

    Optional<ReservationEntity> findFirstByBookIdAndStatusOrderByQueueNoAscCreatedAtAscIdAsc(
            String bookId,
            String status
    );

    Optional<ReservationEntity> findFirstByBookIdOrderByQueueNoDesc(String bookId);

    List<ReservationEntity> findByBookIdAndStatusOrderByQueueNoAscCreatedAtAscIdAsc(String bookId, String status);

    List<ReservationEntity> findByUserIdOrderByCreatedAtDesc(String userId);

    @Query("select r from ReservationEntity r where r.status = 'READY' and r.expiresAt is not null and r.expiresAt <= :nowIso order by r.expiresAt asc")
    List<ReservationEntity> findExpiredReadyReservations(@Param("nowIso") String nowIso);
}
