package catalogservice.dto.response;

import catalogservice.entity.Publisher;
import java.time.Instant;
import java.time.ZoneOffset;

public record PublisherDto(
        String id,
        String name,
        String address,
        String email,
        String phone,
        String website,
        String status,
        Instant createdAt,
        Instant updatedAt
) {
    public static PublisherDto from(Publisher publisher) {
        Instant created = publisher.getCreatedAt() == null ? null : publisher.getCreatedAt().toInstant(ZoneOffset.UTC);
        Instant updated = publisher.getUpdatedAt() == null ? null : publisher.getUpdatedAt().toInstant(ZoneOffset.UTC);
        return new PublisherDto(
                publisher.getId(),
                publisher.getName(),
                publisher.getAddress(),
                publisher.getEmail(),
                publisher.getPhone(),
                publisher.getWebsite(),
                publisher.getStatus(),
                created,
                updated
        );
    }
}
