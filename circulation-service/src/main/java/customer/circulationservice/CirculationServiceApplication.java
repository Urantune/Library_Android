package customer.circulationservice;

import customer.circulationservice.repository.httpClient.LoansClient;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

@SpringBootApplication
@EnableFeignClients(clients = LoansClient.class)
public class CirculationServiceApplication {

    public static void main(String[] args) {
        configureDefaultDatabasePath();
        SpringApplication.run(CirculationServiceApplication.class, args);
    }

    private static void configureDefaultDatabasePath() {
        if (System.getenv("DB_PATH") != null || System.getProperty("DB_PATH") != null) {
            return;
        }

        var codeSource = CirculationServiceApplication.class.getProtectionDomain().getCodeSource();
        if (codeSource == null) {
            throw new IllegalStateException("Cannot determine circulation-service location");
        }

        try {
            Path codeLocation = Path.of(codeSource.getLocation().toURI()).toAbsolutePath();
            Path start = Files.isDirectory(codeLocation) ? codeLocation : codeLocation.getParent();
            if (start == null) {
                throw new IllegalStateException("Cannot determine circulation-service directory");
            }

            for (Path directory = start; directory != null; directory = directory.getParent()) {
                if (Files.isRegularFile(directory.resolve("pom.xml"))
                    && Files.isRegularFile(directory.resolve("src/main/resources/application.properties"))) {
                    System.setProperty("DB_PATH", directory.resolve("data/circulation.db").toString());
                    return;
                }
            }

            System.setProperty("DB_PATH", start.resolve("data/circulation.db").toString());
        } catch (URISyntaxException e) {
            throw new IllegalStateException("Cannot resolve circulation-service location", e);
        }
    }

}
