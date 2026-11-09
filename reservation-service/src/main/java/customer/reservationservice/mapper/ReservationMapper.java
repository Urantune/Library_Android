package customer.reservationservice.mapper;

import customer.reservationservice.dto.response.ReservationResponse;
import customer.reservationservice.entity.Reservation;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface ReservationMapper {
    ReservationResponse toResponse(Reservation reservation);
}
