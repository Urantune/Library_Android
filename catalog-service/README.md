# Catalog books

Run with Java 21: `./mvnw spring-boot:run` (Windows: `mvnw.cmd spring-boot:run`). Port: 8082. The default SQLite file is `catalog-service/data/catalog.db` in the service module, independent of the current working directory. Set DB_PATH to choose another file; create its parent directory first. Flyway initializes fresh databases and applies forward migrations. Do not reset an existing database to fix schema mismatch.

Read API: `GET /api/books?page=0&size=20` and `GET /api/books/{id}`. The list contains ACTIVE books, sorted by title/id. Detail keeps inactive titles readable for historical references. Response uses status/message/data/timestamp/traceId and paginated data.items. Copy counts come from physical book_copies.

Test: `./mvnw test`. Integration tests use real temporary SQLite files in target, not production data.

Write API: `POST /api/books`, `PUT /api/books/{id}`, `DELETE /api/books/{id}`. POST returns 201 and Location; DELETE returns 204 and marks INACTIVE. It never deletes physical copies or historical references. PUT updates book metadata only. ISBN is normalized by removing spaces/hyphens; duplicate ISBN returns 409. Invalid fields or future publication years return 400 with fieldErrors. A new title starts with zero physical copies.

Scope: only Khang's Book module is implemented. Publisher, authors and categories are returned as null without loading other owners' domain objects. Send null publisherId and empty/null authorIds/categoryIds for now. Nonempty references return 409 RELATION_NOT_READY; no relation is silently discarded or written. Existing relation rows remain unchanged. Book timestamps use a Book-only mapped superclass/converter so shared entities and repositories remain identical to the server baseline.

Example JSON: `{"title":"Clean Code","isbn":"9780132350884","publicationYear":2008,"pageCount":464,"publisherId":null,"authorIds":[],"categoryIds":[],"status":"ACTIVE"}`.

Gateway/JWT authorization belongs to shared infrastructure and is not implemented in this milestone. These direct service endpoints are for local development until the shared security layer is ready. Search/filter, Redis, inventory workflow and events remain separate tasks.
