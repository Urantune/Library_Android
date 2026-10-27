package catalogservice.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {
    @Bean
    OpenAPI catalogOpenApi() {
        return new OpenAPI().info(new Info()
            .title("Library Catalog Service API")
            .version("v1")
            .description("Book catalog APIs: list, detail, search, filter, create, update and soft delete.")
            .license(new License().name("Internal assignment")));
    }
}
