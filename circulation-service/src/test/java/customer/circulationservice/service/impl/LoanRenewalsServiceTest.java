package customer.circulationservice.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import customer.circulationservice.dto.request.LoanRenewalRequestDTO;
import customer.circulationservice.dto.response.LoanRenewalResponseDTO;
import customer.circulationservice.entity.LoanRenewals;
import customer.circulationservice.entity.Loans;
import customer.circulationservice.exception.AppException;
import customer.circulationservice.mapper.LoanRenewalsMapper;
import customer.circulationservice.repository.LoanRenewalsRepository;
import customer.circulationservice.repository.LoansRepository;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class LoanRenewalsServiceTest {
    @Mock LoanRenewalsRepository renewalsRepository;
    @Mock LoansRepository loansRepository;
    @Mock LoanRenewalsMapper renewalsMapper;
    @InjectMocks LoanRenewalsService service;

    @Test
    void createsRenewalRequestForBorrowersOwnActiveLoan() {
        String dueAt = java.time.LocalDate.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(7).toString();
        Loans loan = loan("loan-1", "reader-1", "BORROWED", dueAt);
        when(loansRepository.findById("loan-1")).thenReturn(Optional.of(loan));
        when(renewalsRepository.save(any(LoanRenewals.class))).thenAnswer(
                invocation -> invocation.getArgument(0));
        when(renewalsMapper.toResponse(any(LoanRenewals.class))).thenAnswer(invocation -> {
            LoanRenewals renewal = invocation.getArgument(0);
            return LoanRenewalResponseDTO.builder()
                    .id(renewal.getId())
                    .loanId(renewal.getLoanId())
                    .status(renewal.getStatus())
                    .build();
        });

        LoanRenewalResponseDTO response = service.requestRenewal(
                "reader-1", new LoanRenewalRequestDTO("loan-1", "Need more time"));

        ArgumentCaptor<LoanRenewals> captor = ArgumentCaptor.forClass(LoanRenewals.class);
        verify(renewalsRepository).save(captor.capture());
        LoanRenewals saved = captor.getValue();
        assertThat(saved.getRequestedBy()).isEqualTo("reader-1");
        assertThat(saved.getPreviousDueAt()).isEqualTo(dueAt);
        assertThat(saved.getRequestedAt()).isNotBlank();
        assertThat(saved.getStatus()).isEqualTo("REQUESTED");
        assertThat(saved.getReason()).isEqualTo("Need more time");
        assertThat(response.getId()).isEqualTo(saved.getId());
    }

    @Test
    void rejectsRenewalForAnotherUsersLoan() {
        when(loansRepository.findById("loan-1"))
                .thenReturn(Optional.of(loan("loan-1", "another-reader", "BORROWED",
                        Instant.now().plus(7, ChronoUnit.DAYS).toString())));

        assertThatThrownBy(() -> service.requestRenewal(
                "reader-1", new LoanRenewalRequestDTO("loan-1", null)))
                .isInstanceOf(AppException.class);
    }

    private Loans loan(String id, String userId, String status, String dueAt) {
        Loans loan = new Loans();
        loan.setId(id);
        loan.setUserId(userId);
        loan.setStatus(status);
        loan.setDueAt(dueAt);
        return loan;
    }
}
