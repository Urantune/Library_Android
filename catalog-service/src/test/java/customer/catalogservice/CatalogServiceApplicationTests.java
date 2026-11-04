package customer.catalogservice;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(
        classes = catalogservice.CatalogServiceApplication.class,
        properties = {
                "spring.datasource.url=jdbc:sqlite:target/catalog-context-test.db",
                "spring.datasource.driver-class-name=org.sqlite.JDBC",
                "spring.jpa.database-platform=org.hibernate.community.dialect.SQLiteDialect",
                "eureka.client.enabled=false",
                "spring.cloud.discovery.enabled=false"
        }
)
class CatalogServiceApplicationTests {

    @Test
    void contextLoads() {
    }

}