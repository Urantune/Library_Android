package customer.circulationservice.service.impl;

import customer.circulationservice.service.ILoanRenewals;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;

@Service
@FieldDefaults(level = lombok.AccessLevel.PRIVATE, makeFinal = true)
@RequiredArgsConstructor
public class LoanRenewalsService implements ILoanRenewals {
}
