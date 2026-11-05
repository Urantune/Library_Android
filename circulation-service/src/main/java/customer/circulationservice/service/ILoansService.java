package customer.circulationservice.service;

import customer.circulationservice.dto.request.LoanRequestDTO;
import customer.circulationservice.dto.response.LoanResponseDTO;
import customer.circulationservice.dto.response.PageDTO;

public interface ILoansService {
    LoanResponseDTO requestLoan(LoanRequestDTO request);

    PageDTO<LoanResponseDTO> getBorrowedLoans(String userId, int page, int size);

    PageDTO<LoanResponseDTO> getLoanHistory(String userId, int page, int size);
}
