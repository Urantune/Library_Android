package customer.circulationservice.mapper;

import customer.circulationservice.dto.response.LoanItemResponseDTO;
import customer.circulationservice.entity.LoanItems;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface LoanItemsMapper {
    LoanItemResponseDTO toResponse(LoanItems item);
}
