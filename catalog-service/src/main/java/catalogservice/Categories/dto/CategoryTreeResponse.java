package catalogservice.Categories.dto;

import java.util.List;

public record CategoryTreeResponse(
        String id,
        String name,
        String description,
        List<CategoryTreeResponse> children
) {
}
