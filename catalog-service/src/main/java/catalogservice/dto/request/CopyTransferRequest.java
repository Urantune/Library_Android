package catalogservice.dto.request;

import jakarta.validation.constraints.NotBlank;

public record CopyTransferRequest(
        @NotBlank String expectedHolderId,
        @NotBlank String newHolderType,
        @NotBlank String newHolderId,
        @NotBlank String operationId
) {
}
