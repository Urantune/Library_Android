# Agent Trần Đức Toàn

**Đọc trước:** SERVER_ROOT/continue.md ở gốc MSS (cùng cấp các service), đồng thời đọc file tổng README.md và file cá nhân này từ nội dung người dùng đính kèm trong chat. Đọc cả bảy block, đối chiếu phần người 4 của mình. Khi kết thúc, chỉ thay nội dung block người 4 bằng trạng thái mới nhất; giữ nguyên marker và sáu block khác. Hai file hướng dẫn được đính kèm qua chat, không cần nằm trong source hoặc cùng folder; continue.md là file trạng thái thực dùng chung trong checkout MSS.

## 1. Backlog
MSS-024,025,026,027,028,037,038,039. Không có task Android trong backlog này.

## 2. File sở hữu
SERVER_ROOT/catalog-service: publisher/, entity/Publisher.java, repository/PublisherRepository.java.
SERVER_ROOT/reservation-service/ và notification-service/ nghiệp vụ, migration và test.
Kafka schema/envelope trong docs hoặc JSON Schema versioned; không tạo Java common-events library để service phụ thuộc entity nhau. Mẫn giữ broker/Compose; Trí và Khang tự triển khai producer/consumer trong service mình theo contract Toàn.

## 3. Class và function đích
| Class | Hàm | Input -> Output / trách nhiệm |
|---|---|---|
| PublisherService | search(query), detail(id), create(input), update(id,input), deactivate(id) | /api/publishers; invalidate Catalog book cache qua shared component |
| ReservationService | create(userId,bookId,key), listMine(userId,query), cancel(id,userId) | Chỉ tạo khi không còn copy và không duplicate active queue |
| ReservationQueueService | assignNext(bookId,copyId) | Chọn WAITING đầu tiên, claim Catalog, commit READY+outbox |
| ReservationService | fulfill(reservationId,actor,key) | Chuyển holder sang loan, gọi Circulation idempotent; chỉ FULFILLED khi loan đã commit |
| ReservationExpiryJob | expireReady(now) | Release đúng holder, event cho queue tiếp theo |
| CopyAvailableConsumer | onCopyAvailable(event) | Dedup event; gọi queue assignment |
| NotificationService | listMine(userId,query), unreadCount(userId), markRead(id,userId), markAllRead(userId) | Owner-only |
| DeviceTokenService | register(userId,token,platform), revoke(id,userId) | Unique FCM token, deactivate khi logout/device removed |
| NotificationEventConsumer | onLoanApproved(event), onLoanReturned(event), onOverdue(event), onReservationReady(event) | Transaction insert+dedup |
| NotificationComposer | compose(event) | Payload -> title/body/reference; không truy cập DB khác |
| PushSender | send(token,notification) | Adapter FCM, chỉ khi credentials cấu hình |
| OutboxPublisher | publishPendingBatch(limit) | Retry/ack/mark, DLT theo hợp đồng |

## 4. Data giao nhau
Reservation 8084/SQLite reservation.db; Notification 8085/SQLite notification.db; Kafka host 9092/container 29092. READY -> notification qua topic; app lấy REST Gateway, không subscribe Kafka.
Payload theo mục Kafka và Redis trong file tổng; consumer group riêng từng chức năng. Consumer notification tạo IN_APP trước; push thất bại không rollback hay xóa thông báo đã lưu. Duy Khang cần DTO samples và fake fixture tương ứng để dựng UI.

## 5. Nghiệm thu
Queue concurrent không giữ trùng copy; consumer replay không tạo thông báo trùng; Catalog CopyAvailable mới kích hoạt queue; reservation expiry/fulfill có compensation/recovery; notification của user khác trả 404; FCM disabled vẫn xem được in-app.

