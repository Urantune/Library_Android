package customer.reservationservice.client;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
public class CrossServiceClientConfig {
    @Bean
    @ConditionalOnMissingBean(CatalogInventoryClient.class)
    CatalogInventoryClient catalogInventoryClient(
            ObjectMapper mapper,
            @Value("${app.clients.catalog.base-url:http://localhost:8082}") String baseUrl,
            @Value("${app.clients.internal-token:dev-internal-service-token}") String internalToken
    ) {
        return new HttpCatalogInventoryClient(mapper, baseUrl, internalToken);
    }

    @Bean
    @ConditionalOnMissingBean(CirculationLoanClient.class)
    CirculationLoanClient circulationLoanClient(
            ObjectMapper mapper,
            @Value("${app.clients.circulation.base-url:http://localhost:8083}") String baseUrl,
            @Value("${app.clients.internal-token:dev-internal-service-token}") String internalToken
    ) {
        return new HttpCirculationLoanClient(mapper, baseUrl, internalToken);
    }
}
