package catalogservice.entity;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "publishers", uniqueConstraints = @UniqueConstraint(name = "uk_publishers_name", columnNames = "name"))
public class Publisher extends TimestampedEntity {
    @Id
    @Column(columnDefinition = "TEXT", nullable = false)
    private String id;

    @Column(nullable = false, unique = true, columnDefinition = "TEXT")
    private String name;

    @Column(columnDefinition = "TEXT") private String address;
    @Column(columnDefinition = "TEXT") private String email;
    @Column(columnDefinition = "TEXT") private String phone;
    @Column(columnDefinition = "TEXT") private String website;
    @Column(nullable = false, columnDefinition = "TEXT") private String status = "ACTIVE";
    @OneToMany(mappedBy = "publisher") private List<Book> books = new ArrayList<>();

    @PrePersist
    private void assignId() {
        if (id == null || id.isBlank()) id = UUID.randomUUID().toString();
        if (status == null || status.isBlank()) status = "ACTIVE";
    }

    public String getId() { return id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getWebsite() { return website; }
    public void setWebsite(String website) { this.website = website; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public List<Book> getBooks() { return books; }
}
