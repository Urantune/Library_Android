package catalogservice.Categories.controller;

import catalogservice.Categories.dto.CategoryRequest;
import catalogservice.Categories.dto.CategoryResponse;
import catalogservice.Categories.dto.CategoryTreeResponse;
import catalogservice.Categories.dto.PageResponse;
import catalogservice.Categories.entity.CategoryStatus;
import catalogservice.Categories.service.CategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
@Tag(name = "Categories", description = "Quản lý danh mục sách")
public class CategoryController {

    private final CategoryService categoryService;

    @PostMapping
    @Operation(summary = "Tạo danh mục mới")
    public ResponseEntity<CategoryResponse> create(@Valid @RequestBody CategoryRequest request) {
        CategoryResponse created = categoryService.create(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(created.id())
                .toUri();
        return ResponseEntity.created(location).body(created);
    }

    @GetMapping
    @Operation(summary = "Tìm kiếm danh mục (phân trang, lọc theo tên và trạng thái)")
    public PageResponse<CategoryResponse> search(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) CategoryStatus status,
            @PageableDefault(size = 20, sort = "name") Pageable pageable) {
        return categoryService.search(keyword, status, pageable);
    }

    @GetMapping("/tree")
    @Operation(summary = "Lấy cây danh mục cha - con (chỉ ACTIVE)")
    public List<CategoryTreeResponse> tree() {
        return categoryService.getTree();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Lấy chi tiết một danh mục")
    public CategoryResponse getById(@PathVariable String id) {
        return categoryService.getById(id);
    }

    @GetMapping("/{id}/children")
    @Operation(summary = "Lấy các danh mục con trực tiếp")
    public List<CategoryResponse> children(@PathVariable String id) {
        return categoryService.getChildren(id);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Cập nhật danh mục")
    public CategoryResponse update(@PathVariable String id, @Valid @RequestBody CategoryRequest request) {
        return categoryService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Xóa mềm danh mục (status = INACTIVE)")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        categoryService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/restore")
    @Operation(summary = "Khôi phục danh mục đã xóa mềm (status = ACTIVE)")
    public CategoryResponse restore(@PathVariable String id) {
        return categoryService.restore(id);
    }
}
