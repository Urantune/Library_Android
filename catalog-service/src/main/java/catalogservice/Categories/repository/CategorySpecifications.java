package catalogservice.Categories.repository;

import catalogservice.Categories.entity.Category;
import catalogservice.Categories.entity.CategoryStatus;
import org.springframework.data.jpa.domain.Specification;

public final class CategorySpecifications {

    private CategorySpecifications() {
    }

    public static Specification<Category> nameContains(String keyword) {
        return (root, query, cb) -> {
            if (keyword == null || keyword.isBlank()) {
                return cb.conjunction();
            }
            return cb.like(cb.lower(root.get("name")), "%" + keyword.trim().toLowerCase() + "%");
        };
    }

    public static Specification<Category> hasStatus(CategoryStatus status) {
        return (root, query, cb) ->
                status == null ? cb.conjunction() : cb.equal(root.get("status"), status);
    }
}
