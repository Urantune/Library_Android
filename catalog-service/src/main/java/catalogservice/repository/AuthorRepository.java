package catalogservice.repository;

import catalogservice.entity.Author;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface AuthorRepository extends JpaRepository<Author, String> {
    @Query("""
        SELECT a FROM Author a
        WHERE (:name IS NULL OR LOWER(a.name) LIKE LOWER(CONCAT('%', :name, '%')))
          AND (:status IS NULL OR a.status = :status)
        """)
    Page<Author> searchAuthors(
            @Param("name") String name,
            @Param("status") String status,
            Pageable pageable
    );

    boolean existsByName(String name);
}
