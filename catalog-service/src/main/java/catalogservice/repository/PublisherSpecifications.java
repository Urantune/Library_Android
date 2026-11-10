package catalogservice.repository;

import catalogservice.entity.Publisher;
import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import org.springframework.data.jpa.domain.Specification;

public final class PublisherSpecifications {
    private PublisherSpecifications() {
    }

    public static Specification<Publisher> matching(String q, String normalizedStatus) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (normalizedStatus != null && !"ALL".equals(normalizedStatus)) {
                predicates.add(cb.equal(root.get("status"), normalizedStatus));
            }
            if (q != null && !q.isBlank()) {
                String pattern = "%" + q.trim().toLowerCase(Locale.ROOT) + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("name")), pattern),
                        cb.like(cb.lower(cb.coalesce(root.get("email"), "")), pattern),
                        cb.like(cb.lower(cb.coalesce(root.get("address"), "")), pattern),
                        cb.like(cb.lower(cb.coalesce(root.get("phone"), "")), pattern),
                        cb.like(cb.lower(cb.coalesce(root.get("website"), "")), pattern)
                ));
            }
            return cb.and(predicates.toArray(Predicate[]::new));
        };
    }
}
