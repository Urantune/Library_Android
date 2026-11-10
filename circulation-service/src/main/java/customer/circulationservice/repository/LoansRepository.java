package customer.circulationservice.repository;

import customer.circulationservice.entity.Loans;
import java.util.Collection;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface LoansRepository extends JpaRepository<Loans, String> {
    @Query(value = """
            select distinct loan
            from Loans loan
            join LoanItems item on item.loanId = loan.id
            where loan.userId = :userId
              and loan.status in :loanStatuses
              and item.itemStatus = :itemStatus
            order by loan.borrowedAt desc
            """,
            countQuery = """
                    select count(distinct loan.id)
                    from Loans loan
                    join LoanItems item on item.loanId = loan.id
                    where loan.userId = :userId
                      and loan.status in :loanStatuses
                      and item.itemStatus = :itemStatus
                    """)
    Page<Loans> findBorrowedLoans(
            @Param("userId") String userId,
            @Param("loanStatuses") Collection<String> loanStatuses,
            @Param("itemStatus") String itemStatus,
            Pageable pageable);

    Page<Loans> findAllByOrderByRequestedAtDesc(Pageable pageable);

    Page<Loans> findByUserIdAndStatusOrderByRequestedAtDesc(
            String userId, String status, Pageable pageable);

    Page<Loans> findByUserIdOrderByRequestedAtDesc(String userId, Pageable pageable);

    Optional<Loans> findByReservationId(String reservationId);

    Optional<Loans> findByFulfillmentKey(String fulfillmentKey);
}
