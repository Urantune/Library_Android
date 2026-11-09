package customer.reservationservice.repository;

import customer.reservationservice.entity.ReservationEntity;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ReservationRepository extends JpaRepository<ReservationEntity, String> {
    boolean existsByUserIdAndBookIdAndStatusIn(String userId, String bookId, Collection<String> statuses);

    boolean existsByHeldCopyIdAndStatus(String heldCopyId, String status);

    @Query("SELECT COALESCE(MAX(r.queueNo), 0) FROM ReservationEntity r WHERE r.bookId = :bookId")
    int findMaxQueueNoByBookId(@Param("bookId") String bookId);

    @Query("""
            SELECT COUNT(r)
              FROM ReservationEntity r
             WHERE r.bookId = :bookId
               AND r.status = 'WAITING'
               AND r.queueNo <= :queueNo
            """)
    int computeWaitingQueuePosition(@Param("bookId") String bookId, @Param("queueNo") int queueNo);

    Optional<ReservationEntity> findFirstByBookIdAndStatusOrderByQueueNoAscCreatedAtAscIdAsc(String bookId, String status);

    Page<ReservationEntity> findByUserId(String userId, Pageable pageable);

    Page<ReservationEntity> findByUserIdAndStatus(String userId, String status, Pageable pageable);

    @Query("""
            SELECT r
              FROM ReservationEntity r
             WHERE r.status = 'READY'
               AND r.expiresAt IS NOT NULL
               AND r.expiresAt <= :nowIso
             ORDER BY r.expiresAt ASC
            """)
    List<ReservationEntity> findExpiredReadyReservations(@Param("nowIso") String nowIso);
}
