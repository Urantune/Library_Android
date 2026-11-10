package customer.circulationservice.dto.request;

import jakarta.validation.constraints.Future;
import lombok.*;
import lombok.experimental.FieldDefaults;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
@FieldDefaults(level = AccessLevel.PRIVATE)
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class LoanRequestDTO {
     @NotBlank
     String userId;

     @NotEmpty
     List<@Valid LoanItemRequestDTO> items;

     @Future(message = "Hạn trả phải là ngày trong tương lai")
     LocalDate dueAt;
}