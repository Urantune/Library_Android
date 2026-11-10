package catalogservice.entity;

import catalogservice.enums.BookConditionStatus;
import catalogservice.enums.BookCopyStatus;
import catalogservice.persistence.UtcTimestampConverter;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "book_copies", uniqueConstraints = @UniqueConstraint(name = "uk_book_copies_barcode", columnNames = "barcode"))
public class BookCopy extends TimestampedEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "book_id", nullable = false, foreignKey = @ForeignKey(name = "fk_book_copies_book"))
    private Book book;
    @Column(nullable = false, unique = true, columnDefinition = "TEXT") private String barcode;
    @Column(name = "shelf_location", columnDefinition = "TEXT") private String shelfLocation;
    @Enumerated(EnumType.STRING) @Column(name = "condition", columnDefinition = "TEXT") private BookConditionStatus conditionStatus;
    @Enumerated(EnumType.STRING) @Column(name = "circulation_status", columnDefinition = "TEXT") private BookCopyStatus status;
    @Column(name = "holder_type", columnDefinition = "TEXT") private String holderType;
    @Column(name = "holder_id", columnDefinition = "TEXT") private String holderId;
    @Column(name = "aggregate_version", nullable = false) private long aggregateVersion = 1;
    @Convert(converter = UtcTimestampConverter.class)
    @Column(name = "acquired_at", columnDefinition = "TEXT") private LocalDateTime acquiredAt;
    public String getId() { return id; }
    public Book getBook() { return book; }
    public void setBook(Book book) { this.book = book; }
    public String getBarcode() { return barcode; }
    public void setBarcode(String barcode) { this.barcode = barcode; }
    public String getShelfLocation() { return shelfLocation; }
    public void setShelfLocation(String shelfLocation) { this.shelfLocation = shelfLocation; }
    public BookConditionStatus getConditionStatus() { return conditionStatus; }
    public void setConditionStatus(BookConditionStatus conditionStatus) { this.conditionStatus = conditionStatus; }
    public BookCopyStatus getStatus() { return status; }
    public void setStatus(BookCopyStatus status) { this.status = status; }
    public String getHolderType() { return holderType; }
    public void setHolderType(String holderType) { this.holderType = holderType; }
    public String getHolderId() { return holderId; }
    public void setHolderId(String holderId) { this.holderId = holderId; }
    public long getAggregateVersion() { return aggregateVersion; }
    public void setAggregateVersion(long aggregateVersion) { this.aggregateVersion = aggregateVersion; }
    public LocalDateTime getAcquiredAt() { return acquiredAt; }
    public void setAcquiredAt(LocalDateTime acquiredAt) { this.acquiredAt = acquiredAt; }
}
