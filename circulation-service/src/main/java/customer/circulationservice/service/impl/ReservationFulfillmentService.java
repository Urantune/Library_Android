package customer.circulationservice.service.impl;

import customer.circulationservice.dto.request.ReservationFulfillmentRequest;
import customer.circulationservice.dto.response.ReservationFulfillmentResponse;
import customer.circulationservice.entity.LoanItems;
import customer.circulationservice.entity.Loans;
import customer.circulationservice.repository.LoanItemsRepository;
import customer.circulationservice.repository.LoansRepository;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class ReservationFulfillmentService {
    private final LoansRepository loans;
    private final LoanItemsRepository loanItems;

    public ReservationFulfillmentService(LoansRepository loans, LoanItemsRepository loanItems) {
        this.loans = loans;
        this.loanItems = loanItems;
    }

    @Transactional
    public ReservationFulfillmentResponse fulfill(ReservationFulfillmentRequest request, String idempotencyKey) {
        String key = required(idempotencyKey, "Idempotency-Key");
        Loans existing = loans.findByReservationId(request.reservationId()).orElse(null);
        if (existing != null) {
            verifySameFulfillment(existing, request);
            return new ReservationFulfillmentResponse(existing.getId(), existing.getStatus());
        }
        if (loans.findByFulfillmentKey(key).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Idempotency-Key was used for another reservation");
        }
        if (loans.existsById(request.loanId())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Loan ID is already in use");
        }

        String now = Instant.now().toString();
        Loans loan = new Loans();
        loan.setId(request.loanId());
        loan.setUserId(request.userId());
        loan.setReservationId(request.reservationId());
        loan.setFulfillmentKey(key);
        loan.setStatus("APPROVED");
        loan.setAggregateVersion(1);
        loan.setRequestedAt(now);
        loan.setApprovedAt(now);
        loan.setProcessedBy(request.processedBy());
        loan.setRenewCount(0);
        loan.setCreatedAt(now);
        loan.setUpdatedAt(now);
        loans.saveAndFlush(loan);

        LoanItems item = new LoanItems();
        item.setId(request.operationId());
        item.setLoanId(request.loanId());
        item.setBookId(request.bookId());
        item.setCopyId(request.copyId());
        item.setItemStatus("BORROWED");
        item.setFineAmount(0.0);
        loanItems.saveAndFlush(item);

        return new ReservationFulfillmentResponse(request.loanId(), "APPROVED");
    }

    private void verifySameFulfillment(Loans existing, ReservationFulfillmentRequest request) {
        List<LoanItems> items = loanItems.findByLoanIdOrderByIdAsc(existing.getId());
        boolean matches = existing.getId().equals(request.loanId())
                && existing.getUserId().equals(request.userId())
                && items.size() == 1
                && Objects.equals(items.getFirst().getId(), request.operationId())
                && Objects.equals(items.getFirst().getBookId(), request.bookId())
                && Objects.equals(items.getFirst().getCopyId(), request.copyId());
        if (!matches) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Reservation fulfillment payload conflicts with committed loan");
        }
    }

    private static String required(String value, String name) {
        if (value == null || value.isBlank()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, name + " is required");
        return value.trim();
    }
}
