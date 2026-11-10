package catalogservice.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "copy_operations")
public class CopyOperation {
    @Id
    private String id;

    @Column(name = "request_hash", nullable = false)
    private String requestHash;

    @Column(name = "operation_type", nullable = false)
    private String operationType;

    @Column(name = "completed_at", nullable = false)
    private String completedAt;

    protected CopyOperation() {
    }

    public CopyOperation(String id, String requestHash, String operationType, String completedAt) {
        this.id = id;
        this.requestHash = requestHash;
        this.operationType = operationType;
        this.completedAt = completedAt;
    }

    public String getId() { return id; }
    public String getRequestHash() { return requestHash; }
    public String getOperationType() { return operationType; }
    public String getCompletedAt() { return completedAt; }
}
