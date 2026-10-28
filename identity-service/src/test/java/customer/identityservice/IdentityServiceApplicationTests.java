package customer.identityservice;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties={
    "spring.datasource.url=jdbc:sqlite:target/context-auth.db",
    "app.auth.key-dir=target/context-auth-keys",
    "eureka.client.enabled=false",
    "spring.cloud.discovery.enabled=false"
})
class IdentityServiceApplicationTests {

    @Test
    void contextLoads() {
    }

}
