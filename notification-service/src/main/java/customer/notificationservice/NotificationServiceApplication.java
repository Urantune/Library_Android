package customer.notificationservice;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.system.ApplicationHome;

@SpringBootApplication
public class NotificationServiceApplication {

    public static void main(String[] args) {
        configureDefaultDatabasePath();
        SpringApplication.run(NotificationServiceApplication.class, args);
    }

    private static void configureDefaultDatabasePath() {
        if (System.getenv("DB_PATH") != null || System.getProperty("DB_PATH") != null) {
            return;
        }

        // Try candidate paths to find notification-service/data/notification.db or data/notification.db
        Path userDir = Paths.get(System.getProperty("user.dir", ".")).toAbsolutePath();
        Path[] candidates = new Path[] {
            userDir.resolve("data/notification.db"),
            userDir.resolve("notification-service/data/notification.db"),
            new ApplicationHome(NotificationServiceApplication.class).getDir().toPath().toAbsolutePath().resolve("data/notification.db"),
            new ApplicationHome(NotificationServiceApplication.class).getDir().toPath().toAbsolutePath().resolve("notification-service/data/notification.db")
        };

        for (Path candidate : candidates) {
            if (Files.exists(candidate)) {
                System.setProperty("DB_PATH", candidate.toString().replace('\\', '/'));
                return;
            }
        }

        // Search up from userDir and application home to find pom.xml containing notification-service
        Path start = userDir;
        for (Path directory = start; directory != null; directory = directory.getParent()) {
            Path targetDb = directory.resolve("notification-service/data/notification.db");
            if (Files.exists(targetDb)) {
                System.setProperty("DB_PATH", targetDb.toString().replace('\\', '/'));
                return;
            }
            Path directDb = directory.resolve("data/notification.db");
            if (Files.isRegularFile(directory.resolve("pom.xml")) && Files.exists(directDb)) {
                System.setProperty("DB_PATH", directDb.toString().replace('\\', '/'));
                return;
            }
        }

        // Default fallback: ensure directory exists and set path
        Path fallback = userDir.resolve("data/notification.db");
        File parentDir = fallback.toFile().getParentFile();
        if (parentDir != null && !parentDir.exists()) {
            parentDir.mkdirs();
        }
        System.setProperty("DB_PATH", fallback.toString().replace('\\', '/'));
    }

}
