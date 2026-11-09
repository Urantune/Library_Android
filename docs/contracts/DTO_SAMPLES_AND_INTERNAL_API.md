# REST DTO Samples, UI Fixtures & Internal Service Contracts (Owner: Trần Đức Toàn)

Provides concrete REST request/response fixtures for **Nguyễn Duy Khang** (Android Publisher / Reservation / Notification UI) and synchronous `/internal/**` payload contracts for **Dương Phúc Khang** (`catalog-service` inventory) and **Đỗ Trọng Trí** (`circulation-service` fulfillment).

---

## 1. Publisher API (`catalog-service` — `/api/publishers`)

### `POST /api/publishers` / `PUT /api/publishers/{id}` Request
```json
{
  "name": "NXB Trẻ",
  "address": "161B Lý Chính Thắng, Quận 3, TP.HCM",
  "email": "hopthubandoc@nxbtre.com.vn",
  "phone": "028-39316289",
  "website": "https://www.nxbtre.com.vn",
  "status": "ACTIVE"
}
```

### `201 Created` / `200 OK` Single Item Envelope
```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "id": "pub-demo-001",
    "name": "NXB Trẻ",
    "address": "161B Lý Chính Thắng, Quận 3, TP.HCM",
    "email": "hopthubandoc@nxbtre.com.vn",
    "phone": "028-39316289",
    "website": "https://www.nxbtre.com.vn",
    "status": "ACTIVE",
    "createdAt": "2026-11-08T08:00:00Z",
    "updatedAt": "2026-11-08T08:00:00Z"
  },
  "timestamp": "2026-11-08T08:00:00Z",
  "traceId": "trace-pub-001"
}
```

### `GET /api/publishers?q=trẻ&page=0&size=20` List Envelope
```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "items": [
      {
        "id": "pub-demo-001",
        "name": "NXB Trẻ",
        "address": "161B Lý Chính Thắng, Quận 3, TP.HCM",
        "email": "hopthubandoc@nxbtre.com.vn",
        "phone": "028-39316289",
        "website": "https://www.nxbtre.com.vn",
        "status": "ACTIVE",
        "createdAt": "2026-11-08T08:00:00Z",
        "updatedAt": "2026-11-08T08:00:00Z"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1
  },
  "timestamp": "2026-11-08T08:00:01Z",
  "traceId": "trace-pub-list-001"
}
```

---

## 2. Reservation API (`reservation-service` — `/api/reservations`)

### `POST /api/reservations` (Headers: `Authorization: Bearer <jwt>`, optional `Idempotency-Key: <uuid>`)
Request:
```json
{
  "bookId": "book-demo-001"
}
```
Response (`201 Created`):
```json
{
  "status": 201,
  "message": "Created",
  "data": {
    "id": "reservation-demo-001",
    "userId": "user-demo-001",
    "bookId": "book-demo-001",
    "copyId": null,
    "status": "WAITING",
    "queuePosition": 1,
    "readyAt": null,
    "expiresAt": null,
    "fulfilledAt": null,
    "cancelledAt": null,
    "createdAt": "2026-11-08T09:00:00Z"
  },
  "timestamp": "2026-11-08T09:00:00Z",
  "traceId": "trace-res-create-001"
}
```

### `GET /api/reservations/me?page=0&size=20` (`READY` & `WAITING` sample fixture for Android UI)
```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "items": [
      {
        "id": "reservation-demo-002",
        "userId": "user-demo-001",
        "bookId": "9a3019b0-786b-4000-8000-000000000001",
        "copyId": "copy-1",
        "status": "READY",
        "queuePosition": 0,
        "readyAt": "2026-11-08T09:30:00Z",
        "expiresAt": "2026-11-09T09:30:00Z",
        "fulfilledAt": null,
        "cancelledAt": null,
        "createdAt": "2026-11-07T14:00:00Z"
      },
      {
        "id": "reservation-demo-001",
        "userId": "user-demo-001",
        "bookId": "book-demo-001",
        "copyId": null,
        "status": "WAITING",
        "queuePosition": 1,
        "readyAt": null,
        "expiresAt": null,
        "fulfilledAt": null,
        "cancelledAt": null,
        "createdAt": "2026-11-08T09:00:00Z"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 2,
    "totalPages": 1
  },
  "timestamp": "2026-11-08T09:35:00Z",
  "traceId": "trace-res-me-001"
}
```

### `DELETE /api/reservations/{id}` -> `204 No Content`
### `POST /api/reservations/{id}/fulfill` (Staff: `LIBRARIAN`/`ADMIN`, optional `Idempotency-Key`) -> `200 OK` with `status = "FULFILLED"`

---

## 3. Notification API (`notification-service` — `/api/notifications`)

### `GET /api/notifications?page=0&size=20&unreadOnly=false`
```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "items": [
      {
        "id": "notification-demo-002",
        "type": "RESERVATION_READY",
        "title": "Sách đặt trước đã sẵn sàng",
        "body": "Bản sao copy-1 của sách 9a3019b0-786b-4000-8000-000000000001 đang được giữ cho bạn đến 2026-11-09T09:30:00Z.",
        "isRead": false,
        "referenceType": "RESERVATION",
        "referenceId": "reservation-demo-002",
        "readAt": null,
        "createdAt": "2026-11-08T09:30:05Z"
      },
      {
        "id": "notification-demo-001",
        "type": "LOAN_DUE",
        "title": "Loan due soon",
        "body": "Your demo loan is due on 01 November 2026.",
        "isRead": false,
        "referenceType": "LOAN",
        "referenceId": "loan-demo-001",
        "readAt": null,
        "createdAt": "2026-10-28T08:00:00Z"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 2,
    "totalPages": 1
  },
  "timestamp": "2026-11-08T09:36:00Z",
  "traceId": "trace-notif-list-001"
}
```

### `GET /api/notifications/unread-count`
```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "unreadCount": 2
  },
  "timestamp": "2026-11-08T09:36:01Z",
  "traceId": "trace-notif-count-001"
}
```

### `PATCH /api/notifications/{id}/read` -> `200 OK` (returns updated `NotificationResponse`; `404` if owned by another user)
### `PATCH /api/notifications/read-all` -> `200 OK` (`{"updatedCount": 2}`)

### `POST /api/notifications/device-tokens` -> `201 Created`
Request:
```json
{
  "token": "fcm-registration-token-sample-001",
  "platform": "ANDROID"
}
```
Response `data`:
```json
{
  "id": "dt-001",
  "platform": "ANDROID",
  "active": true,
  "createdAt": "2026-11-08T09:40:00Z",
  "updatedAt": "2026-11-08T09:40:00Z"
}
```
### `DELETE /api/notifications/device-tokens/{id}` -> `204 No Content` (`404` if owned by another user)

---

## 4. Synchronous `/internal/**` Contracts Used by `reservation-service`

All `/internal/**` calls carry `X-Internal-Token: ${INTERNAL_SERVICE_TOKEN}` and `X-Trace-Id` and are **not** exposed on Gateway.

### 4.1 `catalog-service` Inventory Endpoints (Owner: Dương Phúc Khang)
- **Availability**: `GET /api/books/{bookId}` (already active) or `GET /internal/books/{bookId}/availability` -> `{"data": {"id": "...", "totalCopies": 2, "availableCopies": 0}}`
- **Claim Copy for Reservation**: `POST /internal/copies/{copyId}/claim`
  ```json
  {
    "bookId": "9a3019b0-786b-4000-8000-000000000001",
    "holderType": "RESERVATION",
    "holderId": "res-2001",
    "operationId": "op-claim-res-2001-copy-1"
  }
  ```
  - `200 OK` if copy transitioned `AVAILABLE -> RESERVED` (or idempotent replay of same `operationId`).
  - `409 Conflict` if copy is already `RESERVED`/`BORROWED`.
- **Release Held Copy**: `POST /internal/copies/{copyId}/release`
  ```json
  {
    "expectedHolderId": "res-2001",
    "operationId": "op-release-res-2001",
    "reason": "RESERVATION_EXPIRED"
  }
  ```
  - `200 OK` when released (or idempotent replay); `catalog-service` then publishes `library.copy.available.v1`.
- **Transfer Copy Holder to Loan**: `POST /internal/copies/{copyId}/transfer-holder`
  ```json
  {
    "expectedHolderId": "res-2001",
    "newHolderType": "LOAN",
    "newHolderId": "loan-from-res-2001",
    "operationId": "op-transfer-res-2001"
  }
  ```
  - `200 OK` when holder atomically switches `res-2001 -> loan-from-res-2001` (or reverse compensation `loan-from-res-2001 -> res-2001`).

### 4.2 `circulation-service` Fulfillment Endpoint (Owner: Đỗ Trọng Trí)
- **Fulfill Reservation into Loan**: `POST /internal/loans/fulfill-reservation` (Header `Idempotency-Key: <key>`)
  ```json
  {
    "loanId": "loan-from-res-2001",
    "reservationId": "res-2001",
    "userId": "user-demo-002",
    "bookId": "9a3019b0-786b-4000-8000-000000000001",
    "copyId": "copy-1",
    "processedBy": "staff-001",
    "operationId": "op-fulfill-loan-res-2001"
  }
  ```
  - `200 OK` / `201 Created` (`{"data": {"loanId": "loan-from-res-2001", "status": "APPROVED"}}`) ONLY after loan transaction is committed in `circulation.db`.

### 4.3 `circulation-service` Return Endpoint
- **Return a borrowed copy**: `POST /internal/loans/{loanId}/return` (Header `X-Internal-Token: ${INTERNAL_SERVICE_TOKEN}`)
  ```json
  {
    "copyId": "copy-1",
    "condition": "GOOD",
    "operationId": "op-return-loan-1001-copy-1"
  }
  ```
  - The loan and item return state plus `library.loan.returned.v1` outbox record commit together in `circulation.db`.
  - Repeating the same `operationId` and payload is idempotent. Catalog consumes the event, releases the matching loan holder when the copy is not damaged/lost, and emits `library.copy.available.v1` through its own outbox.
