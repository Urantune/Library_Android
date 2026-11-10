package catalogservice.service;

import catalogservice.dto.request.BookCopyInput;
import catalogservice.dto.response.BookCopyResponse;
import catalogservice.repository.BookRepository;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class BookCopyService {
    private final JdbcTemplate jdbc;
    private final BookRepository books;
    private final CopyInventoryService inventory;
    private final PublisherCacheInvalidator cache;

    public BookCopyService(JdbcTemplate jdbc, BookRepository books, CopyInventoryService inventory, PublisherCacheInvalidator cache) {
        this.jdbc = jdbc;
        this.books = books;
        this.inventory = inventory;
        this.cache = cache;
    }

    @Transactional(readOnly = true)
    public List<BookCopyResponse> list(String bookId) {
        requireBook(bookId);
        return jdbc.query("SELECT id, accession_code, barcode, shelf_location, condition, circulation_status, created_at FROM book_copies WHERE book_id=? ORDER BY created_at, accession_code",
            (rs, n) -> new BookCopyResponse(rs.getString(1), rs.getString(2), rs.getString(3), rs.getString(4), rs.getString(5), rs.getString(6), rs.getString(7)), bookId);
    }

    @Transactional
    public BookCopyResponse create(String bookId, BookCopyInput input, String traceId) {
        requireBook(bookId);
        String code = input.code().trim();
        String shelf = input.shelfLocation() == null ? null : input.shelfLocation().trim();
        String id = UUID.randomUUID().toString();
        String now = Instant.now().toString();
        try {
            jdbc.update("INSERT INTO book_copies(id,book_id,accession_code,barcode,qr_value,shelf_location,condition,circulation_status,created_at,updated_at,acquired_at,aggregate_version) VALUES(?,?,?,?,?,?, 'GOOD','AVAILABLE',?,?,?,1)",
                id, bookId, code, code, code, shelf, now, now, now);
        } catch (DataIntegrityViolationException ex) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Mã cuốn đã tồn tại");
        }
        inventory.enqueueCopyAvailable(bookId, id, "COPY_ADDED", traceId, 1);
        cache.evictBookCachesAfterCommit();
        return new BookCopyResponse(id, code, code, shelf, "GOOD", "AVAILABLE", now);
    }

    @Transactional
    public void updateStatus(String bookId, String copyId, String status, String traceId) {
        if (status == null || !Set.of("AVAILABLE", "DAMAGED", "LOST").contains(status))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Trạng thái không hợp lệ");
        requireBook(bookId);
        String condition = status.equals("AVAILABLE") ? "GOOD" : status;
        int updated = jdbc.update("UPDATE book_copies SET circulation_status=?, condition=?, updated_at=?, aggregate_version=aggregate_version+1 WHERE id=? AND book_id=? AND holder_id IS NULL AND circulation_status IN ('AVAILABLE','DAMAGED','LOST') AND circulation_status<>?",
            status, condition, Instant.now().toString(), copyId, bookId, status);
        if (updated != 1) throw new ResponseStatusException(HttpStatus.CONFLICT, "Cuốn sách không tồn tại, đang được mượn/giữ hoặc không đổi trạng thái");
        if (status.equals("AVAILABLE")) {
            Long version = jdbc.queryForObject("SELECT aggregate_version FROM book_copies WHERE id=?", Long.class, copyId);
            inventory.enqueueCopyAvailable(bookId, copyId, "COPY_ADDED", traceId, version);
        }
        cache.evictBookCachesAfterCommit();
    }

    private void requireBook(String bookId) {
        if (!books.existsById(bookId)) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy đầu sách");
    }
}
