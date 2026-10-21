# Catalog books

Run from this module with Java 21: `./mvnw spring-boot:run` (Windows: `mvnw.cmd spring-boot:run`). Port: 8082. Default SQLite file: `data/catalog.db`; use DB_PATH to choose an absolute file and create its parent directory first. Flyway initializes fresh databases and applies forward migrations. Do not reset an existing database to fix schema mismatch.

Read API: `GET /api/books?page=0&size=20` and `GET /api/books/{id}`. The list contains ACTIVE books, sorted by title/id. Detail keeps inactive titles readable for historical references. Response uses status/message/data/timestamp/traceId and paginated data.items. Copy counts come from physical book_copies.

Test: `./mvnw test`. Integration tests use real temporary SQLite files in target, not production data.

Gateway/JWT authorization belongs to shared infrastructure and is not implemented in this milestone. These direct service endpoints are for local development until the shared security layer is ready. Search/filter, Redis, inventory workflow and events remain separate tasks.
