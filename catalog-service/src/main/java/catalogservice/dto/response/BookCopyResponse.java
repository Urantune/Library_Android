package catalogservice.dto.response;

public record BookCopyResponse(String id, String code, String barcode, String shelfLocation,
                               String condition, String status, String createdAt) {}
