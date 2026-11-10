package catalogservice.dto.request;

import jakarta.validation.constraints.NotBlank;

public record CopyClaimRequest(
        @NotBlank String bookId,
        @NotBlank String holderType,
        @NotBlank String holderId,
        @NotBlank String operationId
) {
}
