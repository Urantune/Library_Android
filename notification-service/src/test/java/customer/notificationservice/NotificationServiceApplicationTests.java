package customer.notificationservice;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
        "spring.datasource.url=jdbc:sqlite:target/notification-test.db",
        "spring.datasource.driver-class-name=org.sqlite.JDBC",
        "spring.jpa.database-platform=org.hibernate.community.dialect.SQLiteDialect",
        "eureka.client.enabled=false",
        "spring.cloud.discovery.enabled=false"
})
class NotificationServiceApplicationTests {

    @Test
    void contextLoads() {
    }

}