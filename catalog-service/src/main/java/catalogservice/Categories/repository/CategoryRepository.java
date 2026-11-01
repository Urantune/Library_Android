package catalogservice.Categories.repository;

import catalogservice.Categories.entity.Category;
import catalogservice.Categories.entity.CategoryStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.List;
import java.util.Optional;

public interface CategoryRepository extends JpaRepository<Category, String>, JpaSpecificationExecutor<Category> {

    Optional<Category> findByNameIgnoreCaseAndParentId(String name, String parentId);

    Optional<Category> findByNameIgnoreCaseAndParentIdIsNull(String name);

    List<Category> findByParentIdOrderByNameAsc(String parentId);

    List<Category> findByStatusOrderByNameAsc(CategoryStatus status);

    boolean existsByParentIdAndStatus(String parentId, CategoryStatus status);
}
