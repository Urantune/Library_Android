package catalogservice.Categories.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CategoryRequest(
        @NotBlank(message = "Tên danh mục không được để trống")
        @Size(max = 100, message = "Tên danh mục tối đa 100 ký tự")
        String name,

        @Size(max = 500, message = "Mô tả tối đa 500 ký tự")
        String description,

        /** Để null hoặc rỗng nếu là danh mục gốc. */
        String parentId
) {
}
