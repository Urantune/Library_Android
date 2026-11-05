package customer.circulationservice.service.impl;

import customer.circulationservice.dto.request.LoanRenewalRequestDTO;
import customer.circulationservice.dto.response.LoanRenewalResponseDTO;
import customer.circulationservice.entity.LoanRenewals;
import customer.circulationservice.entity.Loans;
import customer.circulationservice.exception.AppException;
import customer.circulationservice.exception.ErrorCode;
import customer.circulationservice.mapper.LoanRenewalsMapper;
import customer.circulationservice.repository.LoanRenewalsRepository;
import customer.circulationservice.repository.LoansRepository;
import customer.circulationservice.service.ILoanRenewals;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@FieldDefaults(level = lombok.AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
public class LoanRenewalsService implements ILoanRenewals {
    LoanRenewalsRepository renewalsRepository;
    LoansRepository loansRepository;
    LoanRenewalsMapper renewalsMapper;

    @Override
    @Transactional
    public LoanRenewalResponseDTO requestRenewal(String userId, LoanRenewalRequestDTO request) {
        Loans loan = loansRepository.findById(request.getLoanId())
                .orElseThrow(() -> new AppException(ErrorCode.LOAN_NOT_FOUND));
        if (!loan.getUserId().equals(userId)) {
            throw new AppException(ErrorCode.LOAN_ACCESS_DENIED);
        }
        if (!"BORROWED".equals(loan.getStatus()) || loan.getDueAt() == null) {
            throw new AppException(ErrorCode.LOAN_NOT_RENEWABLE);
        }

        try {
            if (!Instant.parse(loan.getDueAt()).isAfter(Instant.now())) {
                throw new AppException(ErrorCode.LOAN_NOT_RENEWABLE);
            }
        } catch (DateTimeParseException exception) {
            throw new AppException(ErrorCode.LOAN_NOT_RENEWABLE);
        }

        if (renewalsRepository.existsByLoanIdAndStatus(loan.getId(), "REQUESTED")) {
            throw new AppException(ErrorCode.RENEWAL_ALREADY_PENDING);
        }

        LoanRenewals renewal = new LoanRenewals();
        renewal.setId(UUID.randomUUID().toString());
        renewal.setLoanId(loan.getId());
        renewal.setRequestedBy(userId);
        renewal.setRequestedAt(Instant.now().toString());
        renewal.setPreviousDueAt(loan.getDueAt());
        renewal.setStatus("REQUESTED");
        renewal.setReason(request.getReason());

        return renewalsMapper.toResponse(renewalsRepository.save(renewal));
    }
}
