package customer.circulationservice.repository;

import customer.circulationservice.entity.Loans;
import java.util.Collection;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LoansRepository extends JpaRepository<Loans, String> {
    Page<Loans> findByUserIdAndStatusInOrderByBorrowedAtDesc(
            String userId, Collection<String> statuses, Pageable pageable);
}
