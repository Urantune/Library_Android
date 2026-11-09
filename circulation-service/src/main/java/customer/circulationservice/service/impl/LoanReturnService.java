package customer.circulationservice.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import customer.circulationservice.dto.request.LoanReturnRequest;
import customer.circulationservice.dto.response.LoanReturnedEvent;
import customer.circulationservice.entity.CirculationOutboxEvent;
import customer.circulationservice.entity.LoanItems;
import customer.circulationservice.entity.Loans;
import customer.circulationservice.repository.CirculationOutboxRepository;
import customer.circulationservice.repository.LoanItemsRepository;
import customer.circulationservice.repository.LoansRepository;
import java.time.Instant;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class LoanReturnService {
    public static final String TOPIC_LOAN_RETURNED = "library.loan.returned.v1";
    private static final Set<String> CONDITIONS = Set.of("NEW", "GOOD", "FAIR", "DAMAGED", "LOST");

    private final LoansRepository loans;
    private final LoanItemsRepository items;
    private final CirculationOutboxRepository outbox;
    private final ObjectMapper mapper;

    public LoanReturnService(
            LoansRepository loans,
            LoanItemsRepository items,
            CirculationOutboxRepository outbox,
            ObjectMapper mapper
    ) {
        this.loans = loans;
        this.items = items;
        this.outbox = outbox;
        this.mapper = mapper;
    }

    @Transactional
    public void returnCopy(String loanId, LoanReturnRequest request, String traceId) {
        String normalizedCondition = required(request.condition(), "condition").toUpperCase(java.util.Locale.ROOT);
        if (!CONDITIONS.contains(normalizedCondition)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "condition must be NEW, GOOD, FAIR, DAMAGED, or LOST");
        }
        String operationId = required(request.operationId(), "operationId");
        String copyId = required(request.copyId(), "copyId");

        LoanItems replay = items.findByReturnOperationId(operationId).orElse(null);
        if (replay != null) {
            if (!loanId.equals(replay.getLoanId()) || !copyId.equals(replay.getCopyId())
                    || !normalizedCondition.equals(replay.getConditionOnReturn())) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "operationId was already used for a different return");
            }
            return;
        }

        Loans loan = loans.findById(loanId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Loan not found"));
        if (!Set.of("APPROVED", "BORROWED", "OVERDUE").contains(loan.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Loan is not in a returnable status");
        }
        LoanItems item = items.findByLoanIdOrderByIdAsc(loanId).stream()
                .filter(candidate -> copyId.equals(candidate.getCopyId()))
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Copy is not part of this loan"));
        if (!"BORROWED".equals(item.getItemStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Loan copy is not currently borrowed");
        }

        String returnedAt = Instant.now().toString();
        item.setItemStatus("LOST".equals(normalizedCondition) ? "LOST" : "RETURNED");
        item.setReturnedAt(returnedAt);
        item.setConditionOnReturn(normalizedCondition);
        item.setReturnOperationId(operationId);
        items.saveAndFlush(item);

        boolean allReturned = items.findByLoanIdOrderByIdAsc(loanId).stream()
                .allMatch(candidate -> "RETURNED".equals(candidate.getItemStatus()) || "LOST".equals(candidate.getItemStatus()));
        if (allReturned) {
            loan.setStatus("RETURNED");
            loan.setReturnedAt(returnedAt);
        }
        loan.setUpdatedAt(returnedAt);
        loan.setAggregateVersion(loan.getAggregateVersion() + 1);
        loans.saveAndFlush(loan);

        String eventTrace = traceId != null && traceId.matches("[a-zA-Z0-9-]{1,64}")
                ? traceId
                : UUID.randomUUID().toString();
        LoanReturnedEvent event = new LoanReturnedEvent(
                operationId,
                TOPIC_LOAN_RETURNED,
                1,
                returnedAt,
                eventTrace,
                loanId,
                loan.getAggregateVersion(),
                Map.of(
                        "loanId", loanId,
                        "userId", loan.getUserId(),
                        "bookId", item.getBookId(),
                        "copyId", copyId,
                        "returnedAt", returnedAt,
                        "condition", normalizedCondition,
                        "operationId", operationId
                )
        );
        try {
            outbox.saveAndFlush(new CirculationOutboxEvent(
                    operationId, loanId, TOPIC_LOAN_RETURNED, mapper.writeValueAsString(event), returnedAt));
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Could not serialize loan-returned event", ex);
        }
    }

    private static String required(String value, String name) {
        if (value == null || value.isBlank()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, name + " is required");
        return value.trim();
    }
}
