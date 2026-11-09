package customer.circulationservice.repository;

import customer.circulationservice.entity.LoanItems;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LoanItemsRepository extends JpaRepository <LoanItems, String> {
    java.util.List<LoanItems> findByLoanIdOrderByIdAsc(String loanId);

    java.util.Optional<LoanItems> findByReturnOperationId(String returnOperationId);
}
