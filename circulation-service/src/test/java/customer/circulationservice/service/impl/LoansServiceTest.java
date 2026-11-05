package customer.circulationservice.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import customer.circulationservice.dto.request.LoanItemRequestDTO;
import customer.circulationservice.dto.request.LoanRequestDTO;
import customer.circulationservice.dto.response.LoanItemResponseDTO;
import customer.circulationservice.dto.response.LoanResponseDTO;
import customer.circulationservice.dto.response.UserDto;
import customer.circulationservice.entity.LoanItems;
import customer.circulationservice.entity.Loans;
import customer.circulationservice.mapper.LoanItemsMapper;
import customer.circulationservice.mapper.LoansMapper;
import customer.circulationservice.repository.LoanItemsRepository;
import customer.circulationservice.repository.LoansRepository;
import customer.circulationservice.repository.httpClient.LoansClient;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

@ExtendWith(MockitoExtension.class)
class LoansServiceTest {
    private static final String USER_ID = "user-1";
    private static final String BOOK_ID = "book-1";

    @Mock LoansRepository loansRepository;
    @Mock LoanItemsRepository loanItemsRepository;
    @Mock LoansClient loansClient;
    @Mock LoansMapper loansMapper;
    @Mock LoanItemsMapper loanItemsMapper;
    @InjectMocks LoansService service;

    @Test
    void submitsRequestedLoanAndItemsForAnActiveUser() {
        LoanRequestDTO request = LoanRequestDTO.builder()
                .userId(USER_ID)
                .items(List.of(LoanItemRequestDTO.builder().bookId(BOOK_ID).build()))
                .build();
        when(loansClient.get(USER_ID)).thenReturn(new UserDto.Envelope<>(
                "success", "ok", user(USER_ID, "ACTIVE"), null, null));
        when(loansMapper.toEntity(request)).thenReturn(new Loans());
        when(loansRepository.save(any(Loans.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(loansMapper.toResponse(any(Loans.class))).thenAnswer(invocation -> {
            Loans loan = invocation.getArgument(0);
            return LoanResponseDTO.builder().id(loan.getId()).status(loan.getStatus()).build();
        });
        when(loanItemsMapper.toResponse(any(LoanItems.class))).thenAnswer(invocation -> {
            LoanItems item = invocation.getArgument(0);
            return LoanItemResponseDTO.builder()
                    .id(item.getId())
                    .bookId(item.getBookId())
                    .itemStatus(item.getItemStatus())
                    .build();
        });

        LoanResponseDTO result = service.requestLoan(request);

        ArgumentCaptor<Loans> loanCaptor = ArgumentCaptor.forClass(Loans.class);
        verify(loansRepository).save(loanCaptor.capture());
        Loans savedLoan = loanCaptor.getValue();
        assertThat(savedLoan.getUserId()).isEqualTo(USER_ID);
        assertThat(savedLoan.getStatus()).isEqualTo("REQUESTED");
        assertThat(savedLoan.getRequestedAt()).isNotBlank();
        assertThat(savedLoan.getRenewCount()).isZero();
        assertThat(result.getId()).isEqualTo(savedLoan.getId());
        assertThat(result.getItems()).singleElement()
                .satisfies(item -> {
                    assertThat(item.getBookId()).isEqualTo(BOOK_ID);
                    assertThat(item.getItemStatus()).isEqualTo("REQUESTED");
                });
    }

    @Test
    void tracksOnlyBooksThatRemainBorrowed() {
        Loans loan = new Loans();
        loan.setId("loan-1");
        loan.setUserId(USER_ID);
        loan.setStatus("BORROWED");
        LoanItems borrowedItem = item("item-1", "BORROWED");
        LoanItems returnedItem = item("item-2", "RETURNED");
        when(loansRepository.findByUserIdAndStatusInOrderByBorrowedAtDesc(
                USER_ID, List.of("BORROWED", "OVERDUE"), PageRequest.of(0, 10)))
                .thenReturn(new PageImpl<>(List.of(loan), PageRequest.of(0, 10), 1));
        when(loanItemsRepository.findByLoanIdOrderByIdAsc("loan-1"))
                .thenReturn(List.of(borrowedItem, returnedItem));
        when(loansMapper.toResponse(loan)).thenReturn(
                LoanResponseDTO.builder().id(loan.getId()).status(loan.getStatus()).build());
        when(loanItemsMapper.toResponse(borrowedItem)).thenReturn(
                LoanItemResponseDTO.builder().id(borrowedItem.getId()).itemStatus("BORROWED").build());

        var result = service.getBorrowedLoans(USER_ID, 0, 10);

        assertThat(result.getTotalElements()).isEqualTo(1);
        assertThat(result.getContent()).singleElement()
                .satisfies(currentLoan -> {
                    assertThat(currentLoan.getId()).isEqualTo("loan-1");
                    assertThat(currentLoan.getItems()).extracting(LoanItemResponseDTO::getId)
                            .containsExactly("item-1");
                });
    }

    private UserDto user(String id, String status) {
        return new UserDto(id, "reader", "reader@example.test", "Reader", null,
                "USER", status, null, null);
    }

    private LoanItems item(String id, String status) {
        LoanItems item = new LoanItems();
        item.setId(id);
        item.setBookId(BOOK_ID);
        item.setItemStatus(status);
        return item;
    }
}
