package catalogservice.repository;

import catalogservice.entity.Book;
import catalogservice.enums.BookStatus;
import java.util.Locale;
import org.springframework.data.jpa.domain.Specification;

public final class BookSpecifications {
    private BookSpecifications() { }

    public static Specification<Book> activeSearch(String q, String publisherId, String authorId, String categoryId) {
        return (root, query, builder) -> {
            query.distinct(true);
            var predicates = new java.util.ArrayList<jakarta.persistence.criteria.Predicate>();
            predicates.add(builder.equal(root.<BookStatus>get("status"), BookStatus.ACTIVE));

            String queryText = normalized(q);
            if (queryText != null) {
                String pattern = "%" + queryText + "%";
                predicates.add(builder.or(
                    builder.like(builder.lower(root.<String>get("title")), pattern),
                    builder.like(builder.lower(root.<String>get("isbn")), pattern),
                    builder.like(builder.lower(root.<String>get("description")), pattern)
                ));
            }
            if (normalized(publisherId) != null) {
                predicates.add(builder.equal(root.<String>get("publisherId"), publisherId.trim()));
            }
            if (normalized(authorId) != null) {
                predicates.add(builder.equal(root.joinSet("authors", jakarta.persistence.criteria.JoinType.LEFT).get("id").as(String.class), authorId.trim()));
            }
            if (normalized(categoryId) != null) {
                predicates.add(builder.equal(root.joinSet("categories", jakarta.persistence.criteria.JoinType.LEFT).get("id").as(String.class), categoryId.trim()));
            }
            return builder.and(predicates.toArray(jakarta.persistence.criteria.Predicate[]::new));
        };
    }

    private static String normalized(String value) {
        return value == null || value.isBlank() ? null : value.trim().toLowerCase(Locale.ROOT);
    }
}
