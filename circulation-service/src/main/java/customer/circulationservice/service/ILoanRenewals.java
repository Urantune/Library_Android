package customer.circulationservice.service;

import customer.circulationservice.dto.request.LoanRenewalRequestDTO;
import customer.circulationservice.dto.response.LoanRenewalResponseDTO;

import java.util.List;

public interface ILoanRenewals {
    LoanRenewalResponseDTO requestRenewal(String userId, LoanRenewalRequestDTO request);
    LoanRenewalResponseDTO approveRenewal(String renewalId, String adminUserId);
    List<LoanRenewalResponseDTO> getRenewal();
}
