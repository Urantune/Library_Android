package catalogservice.Categories.entity;

import catalogservice.Categories.entity.CategoryStatus;
import catalogservice.entity.Book;
import catalogservice.entity.TimestampedEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.util.HashSet;
import java.util.Set;

/**
 * Danh mục sách. Hỗ trợ cấu trúc cha - con qua parentId (null = danh mục gốc).
 * created_at / updated_at được quản lý bởi {@link TimestampedEntity}.
 */
@Entity
@Table(name = "categories", indexes = {
        @Index(name = "idx_categories_parent_id", columnList = "parent_id"),
        @Index(name = "idx_categories_status", columnList = "status")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Category extends TimestampedEntity {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "id", nullable = false, updatable = false, columnDefinition = "TEXT")
    @Setter(AccessLevel.NONE)
    private String id;

    // Không còn unique toàn cục: tên chỉ cần duy nhất trong cùng một danh mục cha
    // (được kiểm tra ở CategoryServiceImpl).
    @Column(name = "name", nullable = false, columnDefinition = "TEXT")
    private String name;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    /** id của danh mục cha; null nghĩa là danh mục gốc. */
    @Column(name = "parent_id", columnDefinition = "TEXT")
    private String parentId;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, columnDefinition = "TEXT")
    @Builder.Default
    private CategoryStatus status = CategoryStatus.ACTIVE;

    /** Phía không sở hữu của quan hệ; bảng nối do Book quản lý. */
    @ManyToMany(mappedBy = "categories")
    @Builder.Default
    @Setter(AccessLevel.NONE)
    private Set<Book> books = new HashSet<>();
}