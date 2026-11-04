package customer.circulationservice.mapper;

import customer.circulationservice.dto.request.LoanRequestDTO;
import customer.circulationservice.dto.response.LoanResponseDTO;
import customer.circulationservice.entity.Loans;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface LoansMapper {
    Loans toEntity(LoanRequestDTO request);

    LoanResponseDTO toResponse(Loans loan);
}
