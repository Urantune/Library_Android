package catalogservice.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "authors")
public class Author extends TimestampedEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, columnDefinition = "TEXT") private String name;
    @Column(columnDefinition = "TEXT") private String biography;
    @Column(name = "birth_date", columnDefinition = "DATE") private LocalDate birthDate;
    @Column(columnDefinition = "TEXT") private String nationality;
    @ManyToMany(mappedBy = "authors") private Set<Book> books = new HashSet<>();
    public Long getId() { return id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getBiography() { return biography; }
    public void setBiography(String biography) { this.biography = biography; }
    public LocalDate getBirthDate() { return birthDate; }
    public void setBirthDate(LocalDate birthDate) { this.birthDate = birthDate; }
    public String getNationality() { return nationality; }
    public void setNationality(String nationality) { this.nationality = nationality; }
    public Set<Book> getBooks() { return books; }
}
