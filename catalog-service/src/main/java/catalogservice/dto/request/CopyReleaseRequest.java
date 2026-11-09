package catalogservice.dto.request;

import jakarta.validation.constraints.NotBlank;

public record CopyReleaseRequest(
        @NotBlank String expectedHolderId,
        @NotBlank String operationId,
        @NotBlank String reason
) {
}
