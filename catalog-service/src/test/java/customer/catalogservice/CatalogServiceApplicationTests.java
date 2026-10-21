package customer.catalogservice;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:sqlite:target/context-test.db",
    "eureka.client.enabled=false",
    "spring.cloud.discovery.enabled=false"
})
class CatalogServiceApplicationTests {

    @Test
    void contextLoads() {
    }

}
