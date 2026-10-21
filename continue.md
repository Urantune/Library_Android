# Continue — trạng thái mới nhất của 7 thành viên

File này thuộc gốc MSS, cùng cấp các thư mục services. File tổng và file cá nhân được gửi qua chat; không cần chép hai file hướng dẫn vào đây.

Trước khi sửa code: đọc toàn bộ file, đối chiếu phần của mình với source/branch hiện tại.
Sau khi làm: chỉ thay nội dung giữa marker bắt đầu/kết thúc của mình bằng bản bàn giao mới nhất, không nối dài lịch sử. Giữ nguyên hai marker và sáu phần khác. Đọc lại file mới nhất ngay trước khi lưu để không ghi đè thay đổi của người khác.
Bản mới phải giữ tóm tắt phần đã xong còn liên quan, lỗi/dependency chưa xử lý và bước tiếp tục. Không lưu secret/token/password hay tự ghi PASS khi chưa test.
Nếu phiên bị dừng giữa chừng, cập nhật phần của mình với thay đổi dở dang để phiên sau biết.

Contract hướng dẫn hiện tại: LM-1.1.1.
Khởi tạo file này không có nghĩa tính năng của bất kỳ thành viên nào đã hoàn thành. Các phần chưa có bàn giao phải kiểm tra source thực tế.

===== NGUOI 1 - Dương Phúc Khang =====
Cập nhật: 2026-10-22. Contract LM-1.1.1.
Task / trạng thái: MSS-009, MSS-011 đã có schema/entity/read API và test; PRM-011 demo-ready.
Đã làm: UUID String khớp schema TEXT; Flyway starter Boot 4 và migration page_count/acquired_at; UTC TEXT converter; list/detail DTO + pagination + 400/404.
File/hàm: catalog-service/book/controller/BookController.list/detail; BookReadService.list/detail; BookMapper.toResponse; UtcTimestampConverter.
API: GET /api/books?page=0&size=20 và GET /api/books/{id}; list ACTIVE, detail giữ lịch sử INACTIVE. Port 8082.
Android: fake JSON giữ nguyên, list có phân trang/search; BookDto map dữ liệu API để nối sau. Commit Android 9f9b5df.
Kiểm chứng: Maven test 6 tests passed trên SQLite thật; Flutter book suite 11 passed. Analyze phát hiện 3 lint braces, sẽ sửa trong đợt form tiếp.
Mapping liên owner: chỉ đồng bộ kiểu ID và cột entity/repository Author/Category/Publisher để quan hệ Book đọc được; không làm CRUD các domain đó.
MSS-010/012/013: create/update/soft-delete hoàn tất ở API local, metadata/quan hệ được transaction bảo vệ; ISBN chuẩn hóa và check duplicate; invalid request/ref trả 400, duplicate 409, absent 404.
Kiểm chứng bổ sung: Maven test 12 tests passed, gồm create/update/duplicate/invalid ref/rollback/soft-delete-idempotency; không dùng H2 thay SQLite.
Đang tiếp tục: PRM-012/013 validation/persistence fake và làm sạch checkout MSS local. Backend đọc đã push ở 9a77c6c.
Chưa làm: auth/gateway/security, Redis, Kafka, API client tích hợp; không coi direct endpoints là đã bảo vệ RBAC.
===== HET NGUOI 1 =====

===== NGUOI 2 - Đỗ Trọng Trí =====
Cập nhật: Chưa có bàn giao phiên triển khai được xác minh.
Contract đã đọc: Chưa ghi nhận.
Task / trạng thái: Chưa đối chiếu source.
Đã làm và cần giữ: Chưa ghi nhận; không suy từ tên class trong thiết kế.
File / class / function thay đổi: Chưa ghi nhận.
API / DTO / Kafka / migration ảnh hưởng: Chưa ghi nhận.
Kiểm chứng: Chưa ghi nhận lệnh và kết quả test.
Chưa xong / lỗi / dependency: Đọc file tổng và file cá nhân được đính kèm; kiểm tra branch và dirty state.
Bước tiếp theo: Đối chiếu code thực tế với task được giao, thực hiện đúng phạm vi, rồi thay nội dung phần này bằng kết quả mới nhất.
Commit / branch: Chưa ghi nhận.
===== HET NGUOI 2 =====

===== NGUOI 3 - Trương Thiếu Trọng =====
Cập nhật: Chưa có bàn giao phiên triển khai được xác minh.
Contract đã đọc: Chưa ghi nhận.
Task / trạng thái: Chưa đối chiếu source.
Đã làm và cần giữ: Chưa ghi nhận; không suy từ tên class trong thiết kế.
File / class / function thay đổi: Chưa ghi nhận.
API / DTO / Kafka / migration ảnh hưởng: Chưa ghi nhận.
Kiểm chứng: Chưa ghi nhận lệnh và kết quả test.
Chưa xong / lỗi / dependency: Đọc file tổng và file cá nhân được đính kèm; kiểm tra branch và dirty state.
Bước tiếp theo: Đối chiếu code thực tế với task được giao, thực hiện đúng phạm vi, rồi thay nội dung phần này bằng kết quả mới nhất.
Commit / branch: Chưa ghi nhận.
===== HET NGUOI 3 =====

===== NGUOI 4 - Trần Đức Toàn =====
Cập nhật: Chưa có bàn giao phiên triển khai được xác minh.
Contract đã đọc: Chưa ghi nhận.
Task / trạng thái: Chưa đối chiếu source.
Đã làm và cần giữ: Chưa ghi nhận; không suy từ tên class trong thiết kế.
File / class / function thay đổi: Chưa ghi nhận.
API / DTO / Kafka / migration ảnh hưởng: Chưa ghi nhận.
Kiểm chứng: Chưa ghi nhận lệnh và kết quả test.
Chưa xong / lỗi / dependency: Đọc file tổng và file cá nhân được đính kèm; kiểm tra branch và dirty state.
Bước tiếp theo: Đối chiếu code thực tế với task được giao, thực hiện đúng phạm vi, rồi thay nội dung phần này bằng kết quả mới nhất.
Commit / branch: Chưa ghi nhận.
===== HET NGUOI 4 =====

===== NGUOI 5 - Nguyễn Điền Trung Hiếu =====
Cập nhật: Chưa có bàn giao phiên triển khai được xác minh.
Contract đã đọc: Chưa ghi nhận.
Task / trạng thái: Chưa đối chiếu source.
Đã làm và cần giữ: Chưa ghi nhận; không suy từ tên class trong thiết kế.
File / class / function thay đổi: Chưa ghi nhận.
API / DTO / Kafka / migration ảnh hưởng: Chưa ghi nhận.
Kiểm chứng: Chưa ghi nhận lệnh và kết quả test.
Chưa xong / lỗi / dependency: Đọc file tổng và file cá nhân được đính kèm; kiểm tra branch và dirty state.
Bước tiếp theo: Đối chiếu code thực tế với task được giao, thực hiện đúng phạm vi, rồi thay nội dung phần này bằng kết quả mới nhất.
Commit / branch: Chưa ghi nhận.
===== HET NGUOI 5 =====

===== NGUOI 6 - Nguyễn Duy Khang =====
Cập nhật: Chưa có bàn giao phiên triển khai được xác minh.
Contract đã đọc: Chưa ghi nhận.
Task / trạng thái: Chưa đối chiếu source.
Đã làm và cần giữ: Chưa ghi nhận; không suy từ tên class trong thiết kế.
File / class / function thay đổi: Chưa ghi nhận.
API / DTO / Kafka / migration ảnh hưởng: Chưa ghi nhận.
Kiểm chứng: Chưa ghi nhận lệnh và kết quả test.
Chưa xong / lỗi / dependency: Đọc file tổng và file cá nhân được đính kèm; kiểm tra branch và dirty state.
Bước tiếp theo: Đối chiếu code thực tế với task được giao, thực hiện đúng phạm vi, rồi thay nội dung phần này bằng kết quả mới nhất.
Commit / branch: Chưa ghi nhận.
===== HET NGUOI 6 =====

===== NGUOI 7 - Hà Minh Mẫn =====
Cập nhật: Chưa có bàn giao phiên triển khai được xác minh.
Contract đã đọc: Chưa ghi nhận.
Task / trạng thái: Chưa đối chiếu source.
Đã làm và cần giữ: Chưa ghi nhận; không suy từ tên class trong thiết kế.
File / class / function thay đổi: Chưa ghi nhận.
API / DTO / Kafka / migration ảnh hưởng: Chưa ghi nhận.
Kiểm chứng: Chưa ghi nhận lệnh và kết quả test.
Chưa xong / lỗi / dependency: Đọc file tổng và file cá nhân được đính kèm; kiểm tra branch và dirty state.
Bước tiếp theo: Đối chiếu code thực tế với task được giao, thực hiện đúng phạm vi, rồi thay nội dung phần này bằng kết quả mới nhất.
Commit / branch: Chưa ghi nhận.
===== HET NGUOI 7 =====

