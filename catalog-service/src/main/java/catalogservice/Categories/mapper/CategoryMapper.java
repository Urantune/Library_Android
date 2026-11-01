package catalogservice.Categories.mapper;

import catalogservice.Categories.dto.CategoryResponse;
import catalogservice.Categories.entity.Category;

public final class CategoryMapper {

    private CategoryMapper() {
    }

    public static CategoryResponse toResponse(Category c) {
        return new CategoryResponse(
                c.getId(),
                c.getName(),
                c.getDescription(),
                c.getParentId(),
                c.getStatus(),
                c.getCreatedAt(),
                c.getUpdatedAt());
    }
}
