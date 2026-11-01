package catalogservice.Categories.service.Impl;

import catalogservice.Categories.dto.CategoryRequest;
import catalogservice.Categories.dto.CategoryResponse;
import catalogservice.Categories.dto.CategoryTreeResponse;
import catalogservice.Categories.dto.PageResponse;
import catalogservice.Categories.entity.Category;
import catalogservice.Categories.entity.CategoryStatus;
import catalogservice.Categories.exception.BadRequestException;
import catalogservice.Categories.exception.ConflictException;
import catalogservice.Categories.exception.ResourceNotFoundException;
import catalogservice.Categories.mapper.CategoryMapper;
import catalogservice.Categories.repository.CategoryRepository;
import catalogservice.Categories.repository.CategorySpecifications;
import catalogservice.Categories.service.CategoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CategoryServiceImpl implements CategoryService {

    private static final String ROOT_KEY = "";

    private final CategoryRepository categoryRepository;

    @Override
    @Transactional
    public CategoryResponse create(CategoryRequest request) {
        String name = request.name().trim();
        String parentId = trimToNull(request.parentId());

        validateParent(parentId, null);
        assertNameAvailable(name, parentId, null);

        Category category = Category.builder()
                .name(name)
                .description(trimToNull(request.description()))
                .parentId(parentId)
                .status(CategoryStatus.ACTIVE)
                .build();

        return CategoryMapper.toResponse(categoryRepository.save(category));
    }

    @Override
    public CategoryResponse getById(String id) {
        return CategoryMapper.toResponse(findOrThrow(id));
    }

    @Override
    public PageResponse<CategoryResponse> search(String keyword, CategoryStatus status, Pageable pageable) {
        Specification<Category> spec = Specification
                .where(CategorySpecifications.nameContains(keyword))
                .and(CategorySpecifications.hasStatus(status));

        Page<CategoryResponse> page = categoryRepository.findAll(spec, pageable)
                .map(CategoryMapper::toResponse);
        return PageResponse.from(page);
    }

    @Override
    public List<CategoryResponse> getChildren(String id) {
        findOrThrow(id);
        return categoryRepository.findByParentIdOrderByNameAsc(id).stream()
                .map(CategoryMapper::toResponse)
                .toList();
    }

    @Override
    public List<CategoryTreeResponse> getTree() {
        List<Category> all = categoryRepository.findByStatusOrderByNameAsc(CategoryStatus.ACTIVE);
        Map<String, List<Category>> byParent = all.stream()
                .collect(Collectors.groupingBy(c -> c.getParentId() == null ? ROOT_KEY : c.getParentId()));
        return buildTree(ROOT_KEY, byParent);
    }

    @Override
    @Transactional
    public CategoryResponse update(String id, CategoryRequest request) {
        Category category = findOrThrow(id);
        String name = request.name().trim();
        String parentId = trimToNull(request.parentId());

        validateParent(parentId, id);
        assertNameAvailable(name, parentId, id);

        category.setName(name);
        category.setDescription(trimToNull(request.description()));
        category.setParentId(parentId);

        return CategoryMapper.toResponse(categoryRepository.save(category));
    }

    @Override
    @Transactional
    public void delete(String id) {
        Category category = findOrThrow(id);
        if (category.getStatus() == CategoryStatus.INACTIVE) {
            return; // idempotent
        }
        if (categoryRepository.existsByParentIdAndStatus(id, CategoryStatus.ACTIVE)) {
            throw new ConflictException(
                    "Không thể vô hiệu hóa danh mục đang có danh mục con ACTIVE. Hãy xử lý các danh mục con trước.");
        }
        category.setStatus(CategoryStatus.INACTIVE);
        categoryRepository.save(category);
    }

    @Override
    @Transactional
    public CategoryResponse restore(String id) {
        Category category = findOrThrow(id);
        if (category.getStatus() == CategoryStatus.ACTIVE) {
            return CategoryMapper.toResponse(category);
        }
        if (category.getParentId() != null) {
            Category parent = findOrThrow(category.getParentId());
            if (parent.getStatus() != CategoryStatus.ACTIVE) {
                throw new ConflictException(
                        "Không thể khôi phục vì danh mục cha đang INACTIVE. Hãy khôi phục danh mục cha trước.");
            }
        }
        category.setStatus(CategoryStatus.ACTIVE);
        return CategoryMapper.toResponse(categoryRepository.save(category));
    }

    // ------------------------------------------------------------------ helpers

    private Category findOrThrow(String id) {
        return categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy danh mục với id: " + id));
    }

    /**
     * Kiểm tra danh mục cha hợp lệ: tồn tại, ACTIVE và không tạo vòng lặp.
     *
     * @param selfId id của danh mục đang được cập nhật (null khi tạo mới)
     */
    private void validateParent(String parentId, String selfId) {
        if (parentId == null) {
            return;
        }
        if (parentId.equals(selfId)) {
            throw new BadRequestException("Danh mục không thể là cha của chính nó");
        }
        Category parent = categoryRepository.findById(parentId)
                .orElseThrow(() -> new BadRequestException("Danh mục cha không tồn tại: " + parentId));
        if (parent.getStatus() != CategoryStatus.ACTIVE) {
            throw new BadRequestException("Danh mục cha đang INACTIVE");
        }
        if (selfId != null) {
            Set<String> visited = new HashSet<>();
            Category cursor = parent;
            while (cursor != null && visited.add(cursor.getId())) {
                if (selfId.equals(cursor.getId())) {
                    throw new BadRequestException("Không thể chọn danh mục con/cháu làm danh mục cha (tạo vòng lặp)");
                }
                cursor = cursor.getParentId() == null
                        ? null
                        : categoryRepository.findById(cursor.getParentId()).orElse(null);
            }
        }
    }

    /** Tên danh mục phải duy nhất (không phân biệt hoa thường) trong cùng một danh mục cha. */
    private void assertNameAvailable(String name, String parentId, String selfId) {
        Optional<Category> existing = parentId == null
                ? categoryRepository.findByNameIgnoreCaseAndParentIdIsNull(name)
                : categoryRepository.findByNameIgnoreCaseAndParentId(name, parentId);

        existing.filter(c -> !c.getId().equals(selfId)).ifPresent(c -> {
            throw new ConflictException("Danh mục '" + name + "' đã tồn tại trong cùng danh mục cha");
        });
    }

    private List<CategoryTreeResponse> buildTree(String parentKey, Map<String, List<Category>> byParent) {
        List<Category> nodes = byParent.getOrDefault(parentKey, List.of());
        List<CategoryTreeResponse> result = new ArrayList<>(nodes.size());
        for (Category c : nodes) {
            result.add(new CategoryTreeResponse(
                    c.getId(),
                    c.getName(),
                    c.getDescription(),
                    buildTree(c.getId(), byParent)));
        }
        return result;
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
