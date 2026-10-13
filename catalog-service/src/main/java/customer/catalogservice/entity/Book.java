package customer.catalogservice.entity;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@Table(name = "books", uniqueConstraints = @UniqueConstraint(name = "uk_books_isbn", columnNames = "isbn"))
public class Book extends TimestampedEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(unique = true, columnDefinition = "TEXT") private String isbn;
    @Column(nullable = false, columnDefinition = "TEXT") private String title;
    @Column(columnDefinition = "TEXT") private String description;
    @Column(name = "publication_year", columnDefinition = "INTEGER") private Integer publicationYear;
    @Column(columnDefinition = "TEXT") private String language;
    @Column(name = "page_count", columnDefinition = "INTEGER") private Integer pageCount;
    @Column(name = "cover_url", columnDefinition = "TEXT") private String coverUrl;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "publisher_id", foreignKey = @ForeignKey(name = "fk_books_publisher"))
    private Publisher publisher;
    @Enumerated(EnumType.STRING) @Column(nullable = false, columnDefinition = "TEXT") private BookStatus status;
    @OneToMany(mappedBy = "book") private List<BookCopy> copies = new ArrayList<>();
    @ManyToMany
    @JoinTable(name = "book_authors", joinColumns = @JoinColumn(name = "book_id"), inverseJoinColumns = @JoinColumn(name = "author_id"))
    private Set<Author> authors = new HashSet<>();
    @ManyToMany
    @JoinTable(name = "book_categories", joinColumns = @JoinColumn(name = "book_id"), inverseJoinColumns = @JoinColumn(name = "category_id"))
    private Set<Category> categories = new HashSet<>();
    public Long getId() { return id; }
    public String getIsbn() { return isbn; }
    public void setIsbn(String isbn) { this.isbn = isbn; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public Integer getPublicationYear() { return publicationYear; }
    public void setPublicationYear(Integer publicationYear) { this.publicationYear = publicationYear; }
    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }
    public Integer getPageCount() { return pageCount; }
    public void setPageCount(Integer pageCount) { this.pageCount = pageCount; }
    public String getCoverUrl() { return coverUrl; }
    public void setCoverUrl(String coverUrl) { this.coverUrl = coverUrl; }
    public Publisher getPublisher() { return publisher; }
    public void setPublisher(Publisher publisher) { this.publisher = publisher; }
    public BookStatus getStatus() { return status; }
    public void setStatus(BookStatus status) { this.status = status; }
    public List<BookCopy> getCopies() { return copies; }
    public Set<Author> getAuthors() { return authors; }
    public Set<Category> getCategories() { return categories; }
}
