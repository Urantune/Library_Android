# Kafka Event Contract — Contract LM-1.1.1 (MSS-039)

Owner: **Trần Đức Toàn** (`MSS-039`).
Scope: Versioned Kafka event envelope, topic routing, delivery/deduplication rules, and JSON Schemas (`docs/kafka/schemas/*.schema.json`).
Per team architecture (`ADR-001` & `04_tran_duc_toan.md`), **no shared Java `common-events` library** is created across microservices so services never couple to each other's domain entities. Each service serializes/deserializes against this JSON contract independently.

---

## 1. Broker & Topic Matrix

- **Host bootstrap**: `localhost:9092` (`KAFKA_BOOTSTRAP_SERVERS`)
- **Container bootstrap**: `kafka:19092` (Compose internal) / `29092` per environment override
- **Dead-Letter Topic convention**: `<topic>.dlt` (e.g. `library.loan.approved.v1.dlt`)

| Topic (`type`) | Producer | Consumer Service(s) | Consumer Group ID | Message Key (`aggregateId`) | Schema |
|---|---|---|---|---|---|
| `library.loan.approved.v1` | `circulation-service` | `notification-service` | `notification-loan-approved-v1` | `loanId` | `schemas/library.loan.approved.v1.schema.json` |
| `library.loan.returned.v1` | `circulation-service` | `catalog-service`<br>`notification-service` | `catalog-loan-returned-v1`<br>`notification-loan-returned-v1` | `loanId` | `schemas/library.loan.returned.v1.schema.json` |
| `library.loan.overdue.v1` | `circulation-service` | `notification-service` | `notification-loan-overdue-v1` | `loanId` | `schemas/library.loan.overdue.v1.schema.json` |
| `library.copy.available.v1` | `catalog-service` | `reservation-service` | `reservation-copy-available-v1` | `bookId` | `schemas/library.copy.available.v1.schema.json` |
| `library.reservation.ready.v1` | `reservation-service` | `notification-service` | `notification-reservation-ready-v1` | `reservationId` | `schemas/library.reservation.ready.v1.schema.json` |

> **Note for Compose (`compose.yaml`):** Ensure `library.copy.available.v1` (alongside `library.loan.approved.v1`, `library.loan.returned.v1`, `library.loan.overdue.v1`, `library.reservation.ready.v1`) and corresponding `.dlt` topics are created when `KAFKA_AUTO_CREATE_TOPICS_ENABLE=false`.

---

## 2. Canonical Envelope (`schemaVersion = 1`)

Every Kafka message MUST be a UTF-8 JSON object matching `docs/kafka/schemas/envelope.v1.schema.json`:

```json
{
  "eventId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "type": "library.loan.approved.v1",
  "schemaVersion": 1,
  "occurredAt": "2026-11-08T09:15:00Z",
  "traceId": "trace-loan-approve-001",
  "aggregateId": "loan-001",
  "aggregateVersion": 2,
  "payload": {
    "loanId": "loan-001",
    "userId": "user-demo-001",
    "bookId": "book-demo-001",
    "copyId": "copy-demo-001",
    "approvedAt": "2026-11-08T09:15:00Z",
    "dueAt": null,
    "pickupBy": "2026-11-09T09:15:00Z"
  }
}
```

### Mandatory Rules
1. **Scalar IDs + UTC ISO-8601 timestamps only**: Never embed JPA entities, user emails/passwords, JWTs, refresh tokens, or FCM device tokens inside `payload`.
2. **Transactional Outbox (Producer)**:
   - Insert into `outbox_events` in the **same SQLite transaction** as the domain state change.
   - `OutboxPublisher` polls `PENDING` events due for attempt, sends to Kafka with `key = aggregateId`, **waits for broker ack**, and marks `PUBLISHED` (`published_at = now`).
   - On transient failure, increment `retry_count` with bounded backoff; after `maxRetries` (default `5`), publish to `<topic>.dlt` if broker reachable and mark `FAILED` with `last_error`.
3. **Consumer Deduplication & Bounded Retry**:
   - Each logical feature uses its **own `groupId`** (never share a group across `catalog-service` and `notification-service` on `library.loan.returned.v1`).
   - Record `(consumer_group, event_id)` in `processed_events` in the **same SQLite transaction** as the consumer's state mutation (`notifications` insert or `READY` reservation transition).
   - Duplicate redeliveries with an existing `(consumer_group, event_id)` MUST be ignored idempotently (`200`/ack without duplicate side effects).
   - Do NOT assume ordering across different topics.
   - Transient failures retry finitely (e.g. 3 attempts with exponential backoff) and route poison/exhausted records to `<topic>.dlt`.

---

## 3. Sample Payloads by Topic

### 3.1 Borrow Approved — `library.loan.approved.v1`
```json
{
  "eventId": "11111111-2222-4333-8444-555555555501",
  "type": "library.loan.approved.v1",
  "schemaVersion": 1,
  "occurredAt": "2026-11-08T09:00:00Z",
  "traceId": "req-approve-01",
  "aggregateId": "loan-1001",
  "aggregateVersion": 2,
  "payload": {
    "loanId": "loan-1001",
    "userId": "user-demo-001",
    "bookId": "9a3019b0-786b-4000-8000-000000000001",
    "copyId": "copy-1",
    "approvedAt": "2026-11-08T09:00:00Z",
    "dueAt": "2026-11-22T09:00:00Z",
    "pickupBy": "2026-11-09T09:00:00Z"
  }
}
```

### 3.2 Loan Returned — `library.loan.returned.v1`
```json
{
  "eventId": "11111111-2222-4333-8444-555555555502",
  "type": "library.loan.returned.v1",
  "schemaVersion": 1,
  "occurredAt": "2026-11-15T10:30:00Z",
  "traceId": "req-return-01",
  "aggregateId": "loan-1001",
  "aggregateVersion": 4,
  "payload": {
    "loanId": "loan-1001",
    "userId": "user-demo-001",
    "bookId": "9a3019b0-786b-4000-8000-000000000001",
    "copyId": "copy-1",
    "returnedAt": "2026-11-15T10:30:00Z",
    "condition": "GOOD",
    "operationId": "op-return-loan-1001"
  }
}
```

### 3.3 Loan Overdue — `library.loan.overdue.v1`
```json
{
  "eventId": "11111111-2222-4333-8444-555555555503",
  "type": "library.loan.overdue.v1",
  "schemaVersion": 1,
  "occurredAt": "2026-11-23T00:05:00Z",
  "traceId": "job-overdue-20261123",
  "aggregateId": "loan-1002",
  "aggregateVersion": 3,
  "payload": {
    "loanId": "loan-1002",
    "userId": "user-demo-001",
    "bookId": "9a3019b0-786b-4000-8000-000000000001",
    "copyId": "copy-2",
    "dueAt": "2026-11-22T23:59:59Z",
    "detectedAt": "2026-11-23T00:05:00Z"
  }
}
```

### 3.4 Copy Available — `library.copy.available.v1`
Emitted by `catalog-service` **only after** a physical copy becomes `AVAILABLE` (e.g. after processing `library.loan.returned.v1` with valid `expectedHolderId = loanId` and non-damaged condition, or after `reservation-service` releases an expired/cancelled hold).
```json
{
  "eventId": "11111111-2222-4333-8444-555555555504",
  "type": "library.copy.available.v1",
  "schemaVersion": 1,
  "occurredAt": "2026-11-15T10:30:02Z",
  "traceId": "req-return-01",
  "aggregateId": "9a3019b0-786b-4000-8000-000000000001",
  "aggregateVersion": 5,
  "payload": {
    "bookId": "9a3019b0-786b-4000-8000-000000000001",
    "copyId": "copy-1",
    "availableAt": "2026-11-15T10:30:02Z",
    "reason": "LOAN_RETURNED"
  }
}
```

### 3.5 Reservation Ready — `library.reservation.ready.v1`
```json
{
  "eventId": "11111111-2222-4333-8444-555555555505",
  "type": "library.reservation.ready.v1",
  "schemaVersion": 1,
  "occurredAt": "2026-11-15T10:30:05Z",
  "traceId": "req-return-01",
  "aggregateId": "res-2001",
  "aggregateVersion": 2,
  "payload": {
    "reservationId": "res-2001",
    "userId": "user-demo-002",
    "bookId": "9a3019b0-786b-4000-8000-000000000001",
    "copyId": "copy-1",
    "readyAt": "2026-11-15T10:30:05Z",
    "expiresAt": "2026-11-16T10:30:05Z"
  }
}
```
