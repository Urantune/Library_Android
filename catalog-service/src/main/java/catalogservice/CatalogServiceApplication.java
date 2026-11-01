package catalogservice;

import java.nio.file.Files;
import java.nio.file.Path;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.system.ApplicationHome;

@SpringBootApplication
public class CatalogServiceApplication {

    public static void main(String[] args) {
        configureDefaultDatabasePath();
        SpringApplication.run(CatalogServiceApplication.class, args);
    }

    private static void configureDefaultDatabasePath() {
        if (System.getenv("DB_PATH") != null || System.getProperty("DB_PATH") != null) {
            return;
        }

        Path start = new ApplicationHome(CatalogServiceApplication.class)
            .getDir().toPath().toAbsolutePath();
        for (Path directory = start; directory != null; directory = directory.getParent()) {
            if (Files.isRegularFile(directory.resolve("pom.xml"))
                && Files.isRegularFile(directory.resolve("src/main/resources/application.properties"))) {
                System.setProperty("DB_PATH", directory.resolve("data/catalog.db").toString());
                return;
            }
        }
        System.setProperty("DB_PATH", start.resolve("data/catalog.db").toString());
    }

}
