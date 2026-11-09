package customer.circulationservice.service;

import customer.circulationservice.dto.request.LoanRequestDTO;
import customer.circulationservice.dto.response.LoanResponseDTO;
import customer.circulationservice.dto.response.PageDTO;

public interface ILoansService {
    LoanResponseDTO requestLoan(LoanRequestDTO request);

    PageDTO<LoanResponseDTO> getBorrowedLoans(String userId, int page, int size);

    PageDTO<LoanResponseDTO> getRequestedLoans(String userId, int page, int size);

    PageDTO<LoanResponseDTO> getAllLoans(int page, int size);

    LoanResponseDTO approveLoan(String loanId, String adminUserId);

    PageDTO<LoanResponseDTO> getLoanHistory(String userId, int page, int size);

    LoanResponseDTO rejectLoan(String loanId, String adminUserId, String reason);
}
