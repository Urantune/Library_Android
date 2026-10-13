package customer.catalogservice.entity;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "publishers", uniqueConstraints = @UniqueConstraint(name = "uk_publishers_name", columnNames = "name"))
public class Publisher extends TimestampedEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, columnDefinition = "TEXT") private String name;
    @Column(columnDefinition = "TEXT") private String address;
    @Column(columnDefinition = "TEXT") private String email;
    @Column(columnDefinition = "TEXT") private String phone;
    @OneToMany(mappedBy = "publisher") private List<Book> books = new ArrayList<>();
    public Long getId() { return id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public List<Book> getBooks() { return books; }
}
