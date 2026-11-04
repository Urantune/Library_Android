package customer.circulationservice;

import customer.circulationservice.repository.httpClient.LoansClient;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

@SpringBootApplication
@EnableFeignClients(clients = LoansClient.class)
public class CirculationServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(CirculationServiceApplication.class, args);
    }

}
