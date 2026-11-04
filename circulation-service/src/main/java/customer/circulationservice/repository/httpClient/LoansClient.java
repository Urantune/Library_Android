package customer.circulationservice.repository.httpClient;

import customer.circulationservice.dto.response.UserDto;
import customer.circulationservice.dto.response.UserDto.Envelope;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "identity-service", url = "${service.identity.url}")
public interface LoansClient {
    @GetMapping("/api/users/{id}")
    Envelope<UserDto> get(@PathVariable("id") String userId);
}
