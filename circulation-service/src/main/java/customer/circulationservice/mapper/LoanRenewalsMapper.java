package customer.circulationservice.mapper;

import customer.circulationservice.dto.response.LoanRenewalResponseDTO;
import customer.circulationservice.entity.LoanRenewals;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface LoanRenewalsMapper {
    LoanRenewalResponseDTO toResponse(LoanRenewals renewal);
}
