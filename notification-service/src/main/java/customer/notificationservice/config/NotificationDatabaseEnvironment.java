package customer.notificationservice.config;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

public class NotificationDatabaseEnvironment implements EnvironmentPostProcessor {
    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        Path service = Files.isDirectory(Path.of("notification-service")) ? Path.of("notification-service") : Path.of("");
        String path = service.resolve("data").resolve("notification.db").toAbsolutePath().normalize().toString();
        environment.getPropertySources().addLast(new MapPropertySource("notificationDatabasePath", Map.of("notification.database.path", path)));
    }
}
