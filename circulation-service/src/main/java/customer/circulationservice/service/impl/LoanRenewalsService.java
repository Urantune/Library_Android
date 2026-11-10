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
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

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

        Instant now = Instant.now();
        LocalDate dueDate;
        try {
            dueDate = LocalDate.parse(loan.getDueAt());
        } catch (DateTimeParseException exception) {
            throw new AppException(ErrorCode.LOAN_NOT_RENEWABLE);
        }

        LocalDate today = LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));
        if (!dueDate.isAfter(today)) {
            throw new AppException(ErrorCode.LOAN_NOT_RENEWABLE);
        }

        LoanRenewals renewal = new LoanRenewals();
        renewal.setId(UUID.randomUUID().toString());
        renewal.setLoanId(loan.getId());
        renewal.setRequestedBy(userId);
        renewal.setRequestedAt(now.toString());
        LocalDate newDueDate = dueDate.plusDays(7);
        renewal.setPreviousDueAt(dueDate.toString());
        renewal.setNewDueAt(newDueDate.toString());
        renewal.setStatus("REQUESTED");
        renewal.setReason(request.getReason());

        return renewalsMapper.toResponse(renewalsRepository.save(renewal));
    }

    @Transactional
    public LoanRenewalResponseDTO approveRenewal(String renewalId, String adminUserId) {
        LoanRenewals renewal = renewalsRepository.findById(renewalId)
                .orElseThrow(() -> new AppException(ErrorCode.RENEWAL_NOT_FOUND));

        if (!"REQUESTED".equals(renewal.getStatus())) {
            throw new AppException(ErrorCode.RENEWAL_NOT_PENDING);
        }

        Loans loan = loansRepository.findById(renewal.getLoanId())
                .orElseThrow(() -> new AppException(ErrorCode.LOAN_NOT_FOUND));

        loan.setDueAt(renewal.getNewDueAt());
        loan.setRenewCount(loan.getRenewCount() + 1);
        loan.setUpdatedAt(Instant.now().toString());
        loansRepository.save(loan);

        renewal.setStatus("APPROVED");
        renewal.setApprovedBy(adminUserId);
        renewal.setDecisionAt(Instant.now().toString());

        return renewalsMapper.toResponse(renewalsRepository.save(renewal));
    }

    @Override
    public List<LoanRenewalResponseDTO> getRenewal() {
        return renewalsRepository.findAll().stream()
                .map(renewalsMapper::toResponse)
                .collect(Collectors.toList());
    }
}
