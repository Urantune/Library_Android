package catalogservice.entity;

import catalogservice.persistence.LocalDateStringConverter;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "authors")
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Author extends TimestampedEntity {
    @Id
    @Column(length = 20)
    String id;

    @Column(nullable = false, columnDefinition = "TEXT")
    String name;

    @Column(columnDefinition = "TEXT")
    String bio;

    @Convert(converter = LocalDateStringConverter.class)
    @Column(name = "birth_date", columnDefinition = "TEXT")
    LocalDate birthDate;

    @Column(columnDefinition = "TEXT")
    String country;

    @Column(columnDefinition = "TEXT")
    String status;

    @ManyToMany(mappedBy = "authors")
    Set<Book> books = new HashSet<>();
}
