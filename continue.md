# Continue — trạng thái mới nhất của 7 thành viên

File này thuộc gốc MSS, cùng cấp các thư mục services. File tổng và file cá nhân được gửi qua chat; không cần chép hai file hướng dẫn vào đây.

Trước khi sửa code: đọc toàn bộ file, đối chiếu phần của mình với source/branch hiện tại.
Sau khi làm: chỉ thay nội dung giữa marker bắt đầu/kết thúc của mình bằng bản bàn giao mới nhất, không nối dài lịch sử. Giữ nguyên hai marker và sáu phần khác. Đọc lại file mới nhất ngay trước khi lưu để không ghi đè thay đổi của người khác.
Bản mới phải giữ tóm tắt phần đã xong còn liên quan, lỗi/dependency chưa xử lý và bước tiếp tục. Không lưu secret/token/password hay tự ghi PASS khi chưa test.
Nếu phiên bị dừng giữa chừng, cập nhật phần của mình với thay đổi dở dang để phiên sau biết.

Contract hướng dẫn hiện tại: LM-1.1.1.
Khởi tạo file này không có nghĩa tính năng của bất kỳ thành viên nào đã hoàn thành. Các phần chưa có bàn giao phải kiểm tra source thực tế.

===== NGUOI 1 - Dương Phúc Khang =====
Cập nhật 2026-11-10.
Phạm vi backlog: PRM-001, 003, 006, 007, 008, 011–014 và MSS-009–013, 040–042. Chưa xác nhận hoàn thành 100%.
Phiên Codex 10/11: sửa lỗi biên dịch, trả và cập nhật quan hệ sách, phân trang server, tìm tác giả, xác thực JWT khi ghi, thêm migration tương thích database hiện tại và xử lý Flyway local cho hai lịch sử thiếu đã biết. Flutter analyze phần sách không lỗi; test sách 21/21, auth 19/19; catalog test 19/19. Đã tạo tài khoản thử `abc@gmail.com` trong identity.db với vai trò ADMIN, LIBRARIAN, MEMBER; sao lưu DB trước đó trong identity-service/target. Qua gateway đã kiểm tra đăng nhập, hồ sơ, refresh, logout và CRUD sách kèm quan hệ bằng tài khoản này; CRUD dùng bản sao catalog DB. Windows build thành công và ứng dụng khởi động được; chưa kiểm tra thao tác GUI toàn bộ hoặc Redis/Kafka thật. Các thay đổi đang local, chưa push. JAVA_HOME user là JDK 21; PATH toàn máy chưa đổi được do thiếu quyền registry.
Vai trò và phân quyền:
- Quản lý sách là chức năng dùng chung cho Admin và Staff/Thủ thư (đối chiếu role thực tế `ADMIN`, `LIBRARIAN`): xem danh sách, chi tiết, thêm mới, cập nhật, xóa và tìm kiếm.
- Tích hợp với trang bạn đọc (`MEMBER`): giữ nguyên giao diện `LibraryScreen` và `LibraryBookDetailScreen` của người phụ trách, tiêu thụ `bookListProvider` / `bookDetailProvider` và API `GET /api/books` mà không ảnh hưởng luồng mượn trả hay bản sao `book_copies`.
Backend (catalog-service):
- `BookController`: đọc qua `authorizeRead`; ghi qua `authorizeBookWrite`, xác thực Bearer JWT và role `ADMIN` hoặc `LIBRARIAN`, không tin header role tự khai.
- `BookExceptionHandler`: bổ sung exception handler cho `PublisherException` đảm bảo trả về mã trạng thái (401/403) và cấu trúc lỗi nhất quán.
- `BookCacheConfig` (MSS-041): hiện thực `CachingConfigurer` với `CacheErrorHandler` bắt lỗi kết nối Redis, ghi warning và fallback dữ liệu về DB mà không làm sập API; cache invalidation sau ghi đã được đảm bảo bởi `@CacheEvict` trên create, update và deactivate.
- `OpenApiConfig` (MSS-042): cấu hình OpenAPI/Swagger với `SecurityScheme` Bearer JWT và `SecurityRequirement` cho catalog service.
Frontend (LibPRM):
- `BookDetailScreen`: bổ sung nút và popup xác nhận xóa sách dành cho Admin/Thủ thư, đồng bộ với `BookListScreen`, tự động cập nhật lại danh sách và chi tiết sau khi xóa.
- Nền tảng mạng & auth (PRM-001, 003, 006, 007, 008): ApiClient, AuthInterceptor, AuthSession xử lý gắn JWT, single-flight refresh token và thu hồi phiên / logout chuẩn xác.
File thay đổi:
- `Assigment`: `catalogservice/controller/BookController.java`, `catalogservice/controller/BookExceptionHandler.java`, `catalogservice/config/BookCacheConfig.java`, `catalogservice/config/OpenApiConfig.java`.
- `LibPRM`: `lib/features/books/presentation/screens/book_detail_screen.dart`.
Kiểm chứng và hạn chế:
- Giữ nguyên toàn bộ database SQLite, migration và code của các thành viên khác; giữ file untracked `Project_Group3.zip`. Không push hoặc đổi lịch sử Git.
- Profile local bỏ qua các migration thiếu khi Flyway validate, đồng thời `LocalFlywayConfig` chỉ cho phép đúng hai script/checksum cũ đã biết; cần khôi phục file migration gốc nếu tìm lại được. Migration mới không xóa dữ liệu.
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
Cập nhật 2026-11-04. Đối chiếu file owner `ha_minh_man.md` và team playbook: backend stateful services phải tiếp tục dùng SQLite riêng theo service; PostgreSQL chỉ là hạ tầng MSS-005 trong Compose. Android không có SQLite database dependency.
Task / trạng thái: MSS-001/002/003/004/005/045 được cấu hình trong phạm vi hạ tầng. MSS-001 ghi boundary và database ownership; không sửa domain schema. Runtime Docker và Maven build chưa xác minh được trong môi trường hiện tại.
Đã làm và giữ: parent Maven reactor chỉ gồm 7 canonical services; Eureka 8761; Gateway 8080, routes và trace ID; Compose PostgreSQL 16, Redis, Kafka/topics, Discovery/Gateway cùng apps profile; Dockerfile; Actuator health/readiness/metrics/Prometheus. Năm service stateful dùng SQLite file theo config/migrations hiện có. PostgreSQL không được nối làm datasource domain. `renting-sevice` đã được xóa khỏi repository và Maven reactor trong commit d53fca1.
Đã hoàn tác phần sai phạm vi: bỏ PostgreSQL service DB/role init, PG-specific migrations và test configs; khôi phục SQLite dependencies/config/entity/tests; giữ nguyên dữ liệu `.db` có sẵn. Compose vẫn có PostgreSQL cho MSS-005.
File / class / function: root `pom.xml`, `compose.yaml`, Dockerfile, `.env.example`, README, ADR-001; discovery/gateway configs, Gateway trace filter/test; 7 module POMs; canonical service configs; `continue.md`. Không đổi domain behavior/schema.
API / DTO / Kafka / migration: Không thêm endpoint hay Kafka topic mới trong hạ tầng. Không thêm/sửa domain migration.
Kiểm chứng: `docker compose config --quiet` và Maven wrapper/POM parse cần chạy lại sau rollback. Trước đó Docker Engine không khả dụng và Maven Central không phân giải được DNS; không tuyên bố runtime/test pass. SQLite files có sẵn được giữ nguyên.
Bước triển khai sau khi Docker Desktop chạy: `docker compose config --quiet`; `docker compose up --build -d --wait`; kiểm tra health Discovery/Gateway, Redis/Kafka/Postgres; sau đó `docker compose --profile apps up --build -d --wait --wait-timeout 300`; kiểm tra service health và Eureka registry. Lệnh chi tiết + kết quả mong đợi ở README.
Commit / branch: Chưa commit/push.===== HET NGUOI 7 =====

