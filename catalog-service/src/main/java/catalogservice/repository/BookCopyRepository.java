package catalogservice.repository;

import catalogservice.entity.BookCopy;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import catalogservice.enums.BookCopyStatus;
import java.util.Set;

public interface BookCopyRepository extends JpaRepository<BookCopy, String> {
    @Modifying
    @Query("update BookCopy c set c.status = :targetStatus, c.holderType = :holderType, " +
            "c.holderId = :holderId, c.aggregateVersion = c.aggregateVersion + 1 " +
            "where c.id = :copyId and c.status = :expectedStatus and c.holderId is null")
    int transitionFromStatus(
            @Param("copyId") String copyId,
            @Param("expectedStatus") BookCopyStatus expectedStatus,
            @Param("targetStatus") BookCopyStatus targetStatus,
            @Param("holderType") String holderType,
            @Param("holderId") String holderId
    );

    @Modifying
    @Query("update BookCopy c set c.status = :targetStatus, c.holderType = :targetHolderType, " +
            "c.holderId = :targetHolderId, c.aggregateVersion = c.aggregateVersion + 1 " +
            "where c.id = :copyId and c.holderId = :expectedHolderId and c.status in :expectedStatuses")
    int transitionFromHolder(
            @Param("copyId") String copyId,
            @Param("expectedHolderId") String expectedHolderId,
            @Param("expectedStatuses") Set<BookCopyStatus> expectedStatuses,
            @Param("targetStatus") BookCopyStatus targetStatus,
            @Param("targetHolderType") String targetHolderType,
            @Param("targetHolderId") String targetHolderId
    );
}
