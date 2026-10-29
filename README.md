# Library MSS Server

Branch `Server` contains the Spring Boot server source and has independent history from Android branch `main`.

Modules in this source snapshot: discovery-service, identity-service, catalog-service, circulation-service, reservation-service, notification-service and the existing legacy renting-sevice.

Read `continue.md` before work and update only your assigned section after each session. Runtime SQLite files, Maven caches and build output are excluded from Git; SQL migrations remain tracked.

The source snapshot reflects the current local server files. `api-gateway` is present as the shared Eureka-aware entrypoint on port 8080. Downstream service registration and routing integration remain separate work; Catalog currently has Eureka discovery disabled locally.

Keep separate checkouts for Android and server. Do not merge `main` into `Server` or `Server` into `main`.
