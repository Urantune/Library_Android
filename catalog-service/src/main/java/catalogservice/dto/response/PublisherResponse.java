package catalogservice.dto.response;

import catalogservice.entity.Publisher;
import java.time.LocalDateTime;

public record PublisherResponse(String id, String name, String address, String email,
                                String phone, String website, String status,
                                LocalDateTime createdAt, LocalDateTime updatedAt) {
    public static PublisherResponse from(Publisher publisher) {
        return new PublisherResponse(publisher.getId(), publisher.getName(), publisher.getAddress(),
            publisher.getEmail(), publisher.getPhone(), publisher.getWebsite(), publisher.getStatus(),
            publisher.getCreatedAt(), publisher.getUpdatedAt());
    }
}
