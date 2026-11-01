package catalogservice.Categories.dto;

import catalogservice.Categories.entity.CategoryStatus;

import java.time.LocalDateTime;

public record CategoryResponse(
        String id,
        String name,
        String description,
        String parentId,
        CategoryStatus status,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
