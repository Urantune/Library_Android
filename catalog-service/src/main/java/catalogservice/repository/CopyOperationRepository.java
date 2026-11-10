package catalogservice.repository;

import catalogservice.entity.CopyOperation;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CopyOperationRepository extends JpaRepository<CopyOperation, String> {
}
