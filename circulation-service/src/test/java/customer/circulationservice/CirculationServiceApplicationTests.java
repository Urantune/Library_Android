package customer.circulationservice;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:sqlite:target/circulation-test.db",
        "spring.datasource.driver-class-name=org.sqlite.JDBC",
        "spring.jpa.database-platform=org.hibernate.community.dialect.SQLiteDialect",
        "eureka.client.enabled=false",
        "spring.cloud.discovery.enabled=false"
})
class CirculationServiceApplicationTests {

    @Test
    void contextLoads() {
    }

}