package customer.circulationservice;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:sqlite:target/context-test.db",
        "eureka.client.enabled=false",
        "spring.cloud.discovery.enabled=false"
})
class CirculationServiceApplicationTests {

    @Test
    void contextLoads() {
    }

}
