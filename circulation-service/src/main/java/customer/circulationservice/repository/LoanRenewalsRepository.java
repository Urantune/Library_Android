package customer.circulationservice.repository;

import customer.circulationservice.entity.LoanRenewals;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LoanRenewalsRepository extends JpaRepository<LoanRenewals, String> {
    boolean existsByLoanIdAndStatus(String loanId, String status);

    List<LoanRenewals> findByLoanIdOrderByRequestedAtDesc(String loanId);
}
