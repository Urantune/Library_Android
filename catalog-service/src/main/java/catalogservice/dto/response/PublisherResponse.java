package catalogservice.dto.response;

import catalogservice.entity.Publisher;

public record PublisherResponse(String id, String name, String address, String email,
                                String phone, String website, String status) {
    public static PublisherResponse from(Publisher publisher) {
        return new PublisherResponse(publisher.getId(), publisher.getName(), publisher.getAddress(),
            publisher.getEmail(), publisher.getPhone(), publisher.getWebsite(), publisher.getStatus());
    }
}
