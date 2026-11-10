package catalogservice.dto.request;

public record PublisherQuery(String q, String status, int page, int size) {
}
