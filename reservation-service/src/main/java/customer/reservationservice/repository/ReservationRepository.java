package customer.reservationservice.repository;

import java.util.Collection;
import java.util.Optional;

    boolean existsByUserIdAndBookIdAndStatusIn(String userId, String bookId, Collection<String> statuses);

}
