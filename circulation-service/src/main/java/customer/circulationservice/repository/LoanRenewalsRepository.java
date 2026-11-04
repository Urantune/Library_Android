package customer.circulationservice.repository;

import customer.circulationservice.entity.LoanRenewals;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LoanRenewalsRepository extends JpaRepository<LoanRenewals, String> {
}
