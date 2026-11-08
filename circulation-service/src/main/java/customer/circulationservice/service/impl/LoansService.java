package customer.circulationservice.service.impl;

import customer.circulationservice.dto.request.LoanItemRequestDTO;
import customer.circulationservice.dto.request.LoanRequestDTO;
import customer.circulationservice.dto.response.LoanResponseDTO;
import customer.circulationservice.dto.response.PageDTO;
import customer.circulationservice.dto.response.UserDto;
import customer.circulationservice.entity.LoanItems;
import customer.circulationservice.entity.Loans;
import customer.circulationservice.exception.AppException;
import customer.circulationservice.exception.ErrorCode;
import customer.circulationservice.mapper.LoanItemsMapper;
import customer.circulationservice.mapper.LoansMapper;
import customer.circulationservice.repository.LoanItemsRepository;
import customer.circulationservice.repository.LoansRepository;
import customer.circulationservice.repository.httpClient.LoansClient;
import customer.circulationservice.service.ILoansService;
import feign.FeignException;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@FieldDefaults(level = lombok.AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
@Slf4j
public class LoansService implements ILoansService {
    LoansRepository loansRepository;
    LoanItemsRepository loanItemsRepository;
    LoansClient loansClient;
    LoansMapper loansMapper;
    LoanItemsMapper loanItemsMapper;

    @Override
    @Transactional
    public LoanResponseDTO requestLoan(LoanRequestDTO request) {
        validateItems(request.getItems());
        UserDto user = getActiveUser(request.getUserId());

        String now = Instant.now().toString();
        Loans loan = loansMapper.toEntity(request);
        loan.setId(java.util.UUID.randomUUID().toString());
        loan.setUserId(user.id());
        loan.setStatus("REQUESTED");
        loan.setRequestedAt(now);
        loan.setRenewCount(0);
        loan.setCreatedAt(now);
        loan.setUpdatedAt(now);
        loan = loansRepository.save(loan);
        String loanId = loan.getId();

        List<LoanItems> items = request.getItems().stream()
                .map(item -> toRequestedItem(loanId, item))
                .toList();
        loanItemsRepository.saveAll(items);

        return toResponse(loan, items);
    }

    @Override
    @Transactional(readOnly = true)
    public PageDTO<LoanResponseDTO> getBorrowedLoans(String userId, int page, int size) {
        Page<Loans> loans = loansRepository.findBorrowedLoans(
                userId, List.of("BORROWED", "OVERDUE"), "BORROWED", PageRequest.of(page, size));
        List<String> loanIds = loans.getContent().stream()
                .map(Loans::getId)
                .toList();
        Map<String, List<LoanItems>> itemsByLoanId = loanIds.isEmpty()
                ? Map.of()
                : loanItemsRepository.findByLoanIdInAndItemStatusOrderByIdAsc(loanIds, "BORROWED").stream()
                        .collect(Collectors.groupingBy(LoanItems::getLoanId));
        List<LoanResponseDTO> content = loans.getContent().stream()
                .map(loan -> toResponse(loan, itemsByLoanId.getOrDefault(loan.getId(), List.of())))
                .toList();

        return PageDTO.<LoanResponseDTO>builder()
                .size(loans.getSize())
                .page(loans.getNumber())
                .totalPages(loans.getTotalPages())
                .totalElements(loans.getTotalElements())
                .first(loans.isFirst())
                .last(loans.isLast())
                .content(content)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public PageDTO<LoanResponseDTO> getLoanHistory(String userId, int page, int size) {
        Page<Loans> loans = loansRepository.findByUserIdOrderByRequestedAtDesc(
                userId, PageRequest.of(page, size));
        List<LoanResponseDTO> content = loans.getContent().stream()
                .map(this::toResponseWithAllItems)
                .toList();

        return PageDTO.<LoanResponseDTO>builder()
                .size(loans.getSize())
                .page(loans.getNumber())
                .totalPages(loans.getTotalPages())
                .totalElements(loans.getTotalElements())
                .first(loans.isFirst())
                .last(loans.isLast())
                .content(content)
                .build();
    }

    private UserDto getActiveUser(String userId) {
        final UserDto user;

        try {
            UserDto.Envelope<UserDto> envelope = loansClient.getCurrentUser();

            log.info("Identity response: {}", envelope);

            user = envelope == null ? null : envelope.data();

        } catch (FeignException exception) {

            log.error(
                    "Identity service error - status: {}, body: {}",
                    exception.status(),
                    exception.contentUTF8(),
                    exception
            );

            if (exception.status() == 404) {
                throw new AppException(ErrorCode.USER_NOT_FOUND);
            }

            throw new AppException(ErrorCode.IDENTITY_SERVICE_UNAVAILABLE);
        }

        if (user == null || !userId.equals(user.id())) {
            throw new AppException(ErrorCode.USER_NOT_FOUND);
        }

        if (!"ACTIVE".equalsIgnoreCase(user.status())) {
            throw new AppException(ErrorCode.USER_NOT_ACTIVE);
        }

        return user;
    }

    private void validateItems(List<LoanItemRequestDTO> items) {
        Set<String> requestedItems = new java.util.HashSet<>();
        for (LoanItemRequestDTO item : items) {
            String key = item.getBookId() + "\u0000" + item.getCopyId();
            if (!requestedItems.add(key)) {
                throw new AppException(ErrorCode.DUPLICATE_LOAN_ITEM);
            }
        }
    }

    private LoanItems toRequestedItem(String loanId, LoanItemRequestDTO request) {
        LoanItems item = new LoanItems();
        item.setId(java.util.UUID.randomUUID().toString());
        item.setLoanId(loanId);
        item.setBookId(request.getBookId());
        item.setCopyId(request.getCopyId());
        item.setItemStatus("REQUESTED");
        item.setFineAmount(0.0);
        return item;
    }

    private LoanResponseDTO toResponseWithAllItems(Loans loan) {
        return toResponse(loan, loanItemsRepository.findByLoanIdOrderByIdAsc(loan.getId()));
    }

    private LoanResponseDTO toResponse(Loans loan, List<LoanItems> items) {
        LoanResponseDTO response = loansMapper.toResponse(loan);
        response.setItems(items.stream().map(loanItemsMapper::toResponse).toList());
        return response;
    }
}
