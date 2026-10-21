package customer.catalogservice.entity;

import jakarta.persistence.*;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "categories", uniqueConstraints = @UniqueConstraint(name = "uk_categories_name", columnNames = "name"))
public class Category extends TimestampedEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    @Column(nullable = false, unique = true, columnDefinition = "TEXT") private String name;
    @Column(columnDefinition = "TEXT") private String description;
    @ManyToMany(mappedBy = "categories") private Set<Book> books = new HashSet<>();
    public String getId() { return id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public Set<Book> getBooks() { return books; }
}
