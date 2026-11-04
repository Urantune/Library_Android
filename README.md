# Library Server

This repository contains the seven canonical Spring Boot server services: API Gateway, Discovery, Identity, Catalog, Circulation, Reservation and Notification. They use Java 21, Spring Boot 4.1.1 and Spring Cloud 2025.1.2, managed by the root Maven parent. Stateful services keep their own SQLite database and Flyway migrations.

## Infrastructure tasks

- **MSS-001:** service ownership and persistence boundaries are recorded in [ADR-001](docs/architecture/ADR-001-service-boundaries.md). Each stateful service owns its SQLite file and Flyway migrations; Redis is cache and Kafka carries asynchronous events.
- **MSS-002:** root `pom.xml` is the shared Maven parent/reactor. It pins Java 21 and compatible Spring Boot/Spring Cloud versions. Canonical modules inherit it.
- **MSS-003:** `discovery-service/` runs Eureka on 8761, does not register itself, and exposes health/metrics.
- **MSS-004:** `api-gateway/` runs on 8080, routes existing `/api/auth`, `/api/users`, catalog API paths, and `/api/{identity,catalog,circulation,reservation,notification}/**` through Eureka. Legacy `/{service}/**` aliases are retained. `X-Trace-Id` is forwarded or generated.
- **MSS-005:** root `compose.yaml` starts PostgreSQL, Redis, Kafka, Discovery and Gateway by default. Add `--profile apps` to start all five domain services too. Kafka topics are initialized from the team contract.
- **MSS-045:** all canonical services inherit Actuator and Prometheus dependencies; health, liveness, readiness, metrics and Prometheus endpoints are configured. The root `Dockerfile` builds any canonical module from the Maven reactor and runs as a non-root user.

## Build and test

Run from this repository root in PowerShell. JDK 21 is required. A Maven executable is optional; module Maven wrappers are available.

```powershell
java -version
./discovery-service/mvnw.cmd -B test
./discovery-service/mvnw.cmd -B -pl api-gateway test
./discovery-service/mvnw.cmd -B -pl catalog-service test
./discovery-service/mvnw.cmd -B package -DskipTests
```

The root reactor lists only the seven canonical modules: discovery, gateway, identity, catalog, circulation, reservation and notification. Service tests use SQLite test databases or temporary files and do not require PostgreSQL.

Coding conventions: UTF-8, Java 21, four spaces in Java, two spaces in new YAML/XML, package names beneath each existing service package, and constructor injection. A service must not depend on another service's JAR, entity or repository. Domain migrations stay with their service owner and are append-only.

## Start locally

Start infrastructure with `docker compose up -d postgres redis kafka`, then start each service in a separate terminal from the repository root. Start Discovery first, then Gateway and any domain service being exercised:

```powershell
./discovery-service/mvnw.cmd -pl discovery-service spring-boot:run
./discovery-service/mvnw.cmd -pl api-gateway spring-boot:run
./discovery-service/mvnw.cmd -pl identity-service spring-boot:run
./discovery-service/mvnw.cmd -pl catalog-service spring-boot:run
```

Circulation, reservation and notification use ports 8083, 8084 and 8085. Stateful services use their SQLite files under each service's `data/` directory. Redis and Kafka are optional for local startup unless the feature under test uses them. Configure their addresses with `REDIS_HOST`, `REDIS_PORT`, `KAFKA_BOOTSTRAP_SERVERS`, and set `EUREKA_URL` if Discovery is not at localhost:8761.

## Start with Docker Compose

Docker Desktop must be running. From the repository root:

```powershell
docker compose config --quiet
docker compose up --build -d --wait
docker compose ps
```

This starts PostgreSQL `127.0.0.1:5433`, Redis `127.0.0.1:6379`, Kafka `127.0.0.1:9092`, Discovery `127.0.0.1:8761` and Gateway `0.0.0.0:8080`. Start the domain applications as well with:

```powershell
docker compose --profile apps up --build -d --wait --wait-timeout 300
```

PostgreSQL is available at `127.0.0.1:5433` as infrastructure provisioned for MSS-005; service applications continue to use SQLite per the team contract. The local PostgreSQL admin defaults to `library` / `library_dev`. Override these values in an untracked `.env` file (copy [.env.example](.env.example) as a starting point). Defaults are for local development only. The PostgreSQL container is not a service datasource.

Use `docker compose logs -f postgres identity-service catalog-service` to inspect logs and `docker compose down` to stop while retaining named data volumes. Do not use `docker compose down -v` unless you intend to delete local PostgreSQL, Redis, Kafka and service data volumes.

## Sample checks and expected results

| Case | Command | Expected result |
|---|---|---|
| Compose syntax valid | `docker compose config --quiet` | Exit code 0 |
| Discovery responds | `Invoke-RestMethod http://localhost:8761/actuator/health/readiness` | JSON `status: UP` |
| Eureka registry responds | `Invoke-WebRequest http://localhost:8761/eureka/apps -Headers @{Accept='application/json'}` | HTTP 200; client apps appear after startup convergence |
| Gateway health | `Invoke-RestMethod http://localhost:8080/actuator/health` | JSON `status: UP` |
| Metrics available | `Invoke-WebRequest http://localhost:8080/actuator/prometheus` | HTTP 200 and Prometheus text |
| PostgreSQL ready | `docker compose exec postgres pg_isready -U library -d library` | `accepting connections` |
| PostgreSQL rejects a bad password | `docker compose exec -e PGPASSWORD=wrong postgres psql -h localhost -U library -d library -c 'SELECT 1'` | Authentication error; command exits nonzero |
| Redis healthy | `docker compose exec redis redis-cli ping` | `PONG` |
| Kafka topics exist | `docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:19092 --list` | Four `library.*.v1` topics listed |
| Valid gateway route | `Invoke-WebRequest http://localhost:8080/api/catalog/__probe` | HTTP 404 from Catalog if the service is registered; the probe path is intentionally absent |
| Unknown route | `Invoke-WebRequest http://localhost:8080/api/unknown/__probe` | HTTP 404; no downstream service should be contacted |
| Bad Eureka address | Start a client with `EUREKA_URL=http://localhost:9999/eureka/` | Readiness may be UP but no instance registers; Gateway route returns 503 until a healthy matching instance is available |
| Port conflict | Start another process on 8761/8080 then run Compose | Container fails to bind; stop the conflicting process or change the host port mapping |

PowerShell may throw on expected HTTP 404/503 responses; inspect `$_.Exception.Response.StatusCode` in a `try/catch` or use `curl.exe -i` to see the status.

After `docker compose --profile apps up`, inspect each health endpoint at `/actuator/health`, `/actuator/health/liveness`, `/actuator/health/readiness`, `/actuator/metrics` and `/actuator/prometheus` on its canonical port (8081–8085). Eureka registration may take about a minute after readiness. No domain API behavior or database schema is changed by this infrastructure setup.
