package customer.circulationservice.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
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
import customer.circulationservice.exception.AppException;
import customer.circulationservice.exception.ErrorCode;
import java.util.List;
import java.util.Optional;
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
        when(loansClient.getCurrentUser()).thenReturn(new UserDto.Envelope<>(
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
        when(loansRepository.findBorrowedLoans(
                USER_ID, List.of("BORROWED", "OVERDUE"), "BORROWED", PageRequest.of(0, 10)))
                .thenReturn(new PageImpl<>(List.of(loan), PageRequest.of(0, 10), 1));
        when(loanItemsRepository.findByLoanIdInAndItemStatusOrderByIdAsc(
                List.of("loan-1"), "BORROWED"))
                .thenReturn(List.of(borrowedItem));
        when(loansMapper.toResponse(loan)).thenReturn(
                LoanResponseDTO.builder().id(loan.getId()).userId(USER_ID).status(loan.getStatus()).build());
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

    @Test
    void listsAllLoansWithEveryLoanItemForAdmin() {
        Loans loan = new Loans();
        loan.setId("loan-admin-1");
        loan.setUserId(USER_ID);
        loan.setStatus("REQUESTED");
        LoanItems requestedItem = item("item-requested", "REQUESTED");
        LoanItems returnedItem = item("item-returned", "RETURNED");
        requestedItem.setLoanId(loan.getId());
        returnedItem.setLoanId(loan.getId());
        when(loansRepository.findAllByOrderByRequestedAtDesc(PageRequest.of(0, 10)))
                .thenReturn(new PageImpl<>(List.of(loan), PageRequest.of(0, 10), 1));
        when(loanItemsRepository.findByLoanIdInOrderByIdAsc(List.of(loan.getId())))
                .thenReturn(List.of(requestedItem, returnedItem));
        when(loansMapper.toResponse(loan)).thenReturn(
                LoanResponseDTO.builder().id(loan.getId()).status(loan.getStatus()).build());
        when(loanItemsMapper.toResponse(requestedItem)).thenReturn(
                LoanItemResponseDTO.builder().id(requestedItem.getId())
                        .itemStatus(requestedItem.getItemStatus()).build());
        when(loanItemsMapper.toResponse(returnedItem)).thenReturn(
                LoanItemResponseDTO.builder().id(returnedItem.getId())
                        .itemStatus(returnedItem.getItemStatus()).build());

        var result = service.getAllLoans(0, 10);

        assertThat(result.getTotalElements()).isEqualTo(1);
        assertThat(result.getContent()).singleElement()
                .satisfies(currentLoan -> {
                    assertThat(currentLoan.getId()).isEqualTo(loan.getId());
                    assertThat(currentLoan.getItems())
                            .extracting(LoanItemResponseDTO::getItemStatus)
                            .containsExactly("REQUESTED", "RETURNED");
                });
    }

    @Test
    void listsOnlyRequestedLoansForTheSpecifiedUser() {
        Loans loan = new Loans();
        loan.setId("loan-requested-1");
        loan.setUserId(USER_ID);
        loan.setStatus("REQUESTED");
        LoanItems requestedItem = item("item-requested-1", "REQUESTED");
        requestedItem.setLoanId(loan.getId());
        when(loansRepository.findByUserIdAndStatusOrderByRequestedAtDesc(
                USER_ID, "REQUESTED", PageRequest.of(0, 10)))
                .thenReturn(new PageImpl<>(List.of(loan), PageRequest.of(0, 10), 1));
        when(loanItemsRepository.findByLoanIdInOrderByIdAsc(List.of(loan.getId())))
                .thenReturn(List.of(requestedItem));
        when(loansMapper.toResponse(loan)).thenReturn(
                LoanResponseDTO.builder().id(loan.getId()).userId(USER_ID).status(loan.getStatus()).build());
        when(loanItemsMapper.toResponse(requestedItem)).thenReturn(
                LoanItemResponseDTO.builder().id(requestedItem.getId())
                        .itemStatus(requestedItem.getItemStatus()).build());

        var result = service.getRequestedLoans(USER_ID, 0, 10);

        assertThat(result.getTotalElements()).isEqualTo(1);
        assertThat(result.getContent()).singleElement()
                .satisfies(requestedLoan -> {
                    assertThat(requestedLoan.getUserId()).isEqualTo(USER_ID);
                    assertThat(requestedLoan.getStatus()).isEqualTo("REQUESTED");
                    assertThat(requestedLoan.getItems()).singleElement()
                            .satisfies(item -> assertThat(item.getItemStatus()).isEqualTo("REQUESTED"));
                });
    }

    @Test
    void approvingRequestedLoanMarksLoanAndAllItemsBorrowed() {
        Loans loan = new Loans();
        loan.setId("loan-to-approve");
        loan.setUserId(USER_ID);
        loan.setStatus("REQUESTED");
        LoanItems firstItem = item("item-1", "REQUESTED");
        LoanItems secondItem = item("item-2", "REQUESTED");
        firstItem.setLoanId(loan.getId());
        secondItem.setLoanId(loan.getId());
        when(loansRepository.findById(loan.getId())).thenReturn(Optional.of(loan));
        when(loanItemsRepository.findByLoanIdOrderByIdAsc(loan.getId()))
                .thenReturn(List.of(firstItem, secondItem));
        when(loansRepository.save(loan)).thenAnswer(invocation -> invocation.getArgument(0));
        when(loanItemsRepository.saveAll(List.of(firstItem, secondItem)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(loansMapper.toResponse(loan)).thenReturn(
                LoanResponseDTO.builder().id(loan.getId()).status(loan.getStatus()).build());
        when(loanItemsMapper.toResponse(firstItem)).thenAnswer(invocation ->
                LoanItemResponseDTO.builder().id(firstItem.getId())
                        .itemStatus(firstItem.getItemStatus()).build());
        when(loanItemsMapper.toResponse(secondItem)).thenAnswer(invocation ->
                LoanItemResponseDTO.builder().id(secondItem.getId())
                        .itemStatus(secondItem.getItemStatus()).build());

        LoanResponseDTO result = service.approveLoan(loan.getId(), "admin-1");

        assertThat(loan.getStatus()).isEqualTo("BORROWED");
        assertThat(loan.getApprovedAt()).isNotBlank();
        assertThat(loan.getBorrowedAt()).isEqualTo(loan.getApprovedAt());
        assertThat(loan.getProcessedBy()).isEqualTo("admin-1");
        assertThat(loan.getUpdatedAt()).isNotBlank();
        assertThat(firstItem.getItemStatus()).isEqualTo("BORROWED");
        assertThat(secondItem.getItemStatus()).isEqualTo("BORROWED");
        assertThat(result.getItems()).extracting(LoanItemResponseDTO::getItemStatus)
                .containsExactly("BORROWED", "BORROWED");
    }

    @Test
    void rejectsApprovalWhenLoanIsNotRequested() {
        Loans loan = new Loans();
        loan.setId("loan-already-borrowed");
        loan.setStatus("BORROWED");
        when(loansRepository.findById(loan.getId())).thenReturn(Optional.of(loan));

        assertThatThrownBy(() -> service.approveLoan(loan.getId(), "admin-1"))
                .isInstanceOf(AppException.class)
                .extracting(exception -> ((AppException) exception).getErrorCode())
                .isEqualTo(ErrorCode.LOAN_NOT_APPROVABLE);
    }

    private UserDto user(String id, String status) {
        return new UserDto(id, "reader", "reader@example.test", "Reader", null,
                "USER", status, null, null);
    }

    private LoanItems item(String id, String status) {
        LoanItems item = new LoanItems();
        item.setId(id);
        item.setLoanId("loan-1");
        item.setBookId(BOOK_ID);
        item.setItemStatus(status);
        return item;
    }
}
