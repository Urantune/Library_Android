package customer.circulationservice.service;

import customer.circulationservice.dto.request.LoanRenewalRequestDTO;
import customer.circulationservice.dto.response.LoanRenewalResponseDTO;

public interface ILoanRenewals {
    LoanRenewalResponseDTO requestRenewal(String userId, LoanRenewalRequestDTO request);
}
