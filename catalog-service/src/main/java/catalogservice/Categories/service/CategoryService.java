package catalogservice.Categories.service;

import catalogservice.Categories.dto.CategoryRequest;
import catalogservice.Categories.dto.CategoryResponse;
import catalogservice.Categories.dto.CategoryTreeResponse;
import catalogservice.Categories.dto.PageResponse;
import catalogservice.Categories.entity.CategoryStatus;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface CategoryService {

    CategoryResponse create(CategoryRequest request);

    CategoryResponse getById(String id);

    PageResponse<CategoryResponse> search(String keyword, CategoryStatus status, Pageable pageable);

    List<CategoryResponse> getChildren(String id);

    List<CategoryTreeResponse> getTree();

    CategoryResponse update(String id, CategoryRequest request);

    void delete(String id);

    CategoryResponse restore(String id);
}
