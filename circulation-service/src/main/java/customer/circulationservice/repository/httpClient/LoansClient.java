package customer.circulationservice.repository.httpClient;

import customer.circulationservice.config.FeignClientConfig;
import customer.circulationservice.dto.response.UserDto;
import customer.circulationservice.dto.response.UserDto.Envelope;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(
        name = "identity-service",
        url = "${service.identity.url}",
        configuration = FeignClientConfig.class
)
public interface LoansClient {

    @GetMapping("/api/users/me")
    Envelope<UserDto> getCurrentUser();
}