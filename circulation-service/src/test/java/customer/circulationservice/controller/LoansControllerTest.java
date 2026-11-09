package customer.circulationservice.controller;

import customer.circulationservice.dto.response.PageDTO;
import customer.circulationservice.dto.response.LoanResponseDTO;
import customer.circulationservice.exception.AppException;
import customer.circulationservice.exception.ErrorCode;
import customer.circulationservice.service.ILoansService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class LoansControllerTest {
    @Mock
    private ILoansService loansService;

    @InjectMocks
    private LoansController controller;

    @Test
    void deniesAdminLoanListToNonAdmin() {
        assertThatThrownBy(() -> controller.getAllLoans("USER", 0, 20))
                .isInstanceOf(AppException.class)
                .extracting(exception -> ((AppException) exception).getErrorCode())
                .isEqualTo(ErrorCode.ADMIN_ACCESS_DENIED);

        verifyNoInteractions(loansService);
    }

    @Test
    void returnsPagedLoansForAdmin() {
        PageDTO<LoanResponseDTO> page = PageDTO.<LoanResponseDTO>builder()
                .size(20)
                .page(0)
                .totalPages(0)
                .totalElements(0)
                .first(true)
                .last(true)
                .content(List.of())
                .build();
        when(loansService.getAllLoans(0, 20)).thenReturn(page);

        var response = controller.getAllLoans("USER, ADMIN", 0, 20);

        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat(response.getBody().getMessage()).isEqualTo("All loans");
        verify(loansService).getAllLoans(0, 20);
    }

    @Test
    void deniesLoanApprovalToNonAdmin() {
        assertThatThrownBy(() -> controller.approveLoan("loan-1", "user-1", "USER"))
                .isInstanceOf(AppException.class)
                .extracting(exception -> ((AppException) exception).getErrorCode())
                .isEqualTo(ErrorCode.ADMIN_ACCESS_DENIED);

        verifyNoInteractions(loansService);
    }

    @Test
    void adminApprovalPassesTrustedAdminIdToService() {
        LoanResponseDTO loan = LoanResponseDTO.builder().id("loan-1").status("BORROWED").build();
        when(loansService.approveLoan("loan-1", "admin-1")).thenReturn(loan);

        var response = controller.approveLoan("loan-1", "admin-1", "ADMIN");

        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat(response.getBody().getResult().getStatus()).isEqualTo("BORROWED");
        verify(loansService).approveLoan("loan-1", "admin-1");
    }

    @Test
    void requestedLoansEndpointVerifiesOwnerBeforeListing() {
        PageDTO<LoanResponseDTO> page = PageDTO.<LoanResponseDTO>builder()
                .size(20)
                .page(0)
                .totalPages(0)
                .totalElements(0)
                .first(true)
                .last(true)
                .content(List.of())
                .build();
        when(loansService.getRequestedLoans("user-1", 0, 20)).thenReturn(page);

        var response = controller.getRequestedLoans("user-1", "user-1", 0, 20);

        assertThat(response.getStatusCode().value()).isEqualTo(200);
        assertThat(response.getBody().getMessage()).isEqualTo("Requested loans");
        verify(loansService).getRequestedLoans("user-1", 0, 20);
    }
}
