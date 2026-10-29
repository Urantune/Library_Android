# API Gateway

Spring Cloud Gateway is the single HTTP entrypoint for the services. It listens on port `8080`, discovers services through Eureka on `8761`, and uses Spring Cloud LoadBalancer for `lb://` routes.

## Routes

| Client path | Eureka service | Forwarded path |
|---|---|---|
| `/api/auth/**`, `/api/users/**` | `IDENTITY-SERVICE` | unchanged |
| `/api/books/**`, `/api/authors/**`, `/api/categories/**`, `/api/publishers/**` | `CATALOG-SERVICE` | unchanged |
| `/identity/**` | `IDENTITY-SERVICE` | prefix removed |
| `/catalog/**` | `CATALOG-SERVICE` | prefix removed |
| `/circulation/**` | `CIRCULATION-SERVICE` | prefix removed |
| `/reservation/**` | `RESERVATION-SERVICE` | prefix removed |
| `/notification/**` | `NOTIFICATION-SERVICE` | prefix removed |

Start Discovery first, then the backend services, then Gateway. Services must register with Eureka using the matching `spring.application.name`. Catalog currently disables Eureka discovery in its local properties, so the `/api/books/**` and `/catalog/**` routes become available after Catalog is enabled as a Eureka client.

Run from this directory with `.\mvnw.cmd spring-boot:run`. Override the port or registry using `SERVER_PORT` and `EUREKA_URL`.

The gateway routes requests and performs service discovery/load balancing. It does not yet enforce JWT authorization; downstream services and gateway security still need integration before treating it as the security boundary.