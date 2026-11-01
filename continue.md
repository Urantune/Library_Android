# Continue — trạng thái mới nhất của 7 thành viên

File này thuộc gốc MSS, cùng cấp các thư mục services. File tổng và file cá nhân được gửi qua chat; không cần chép hai file hướng dẫn vào đây.

Trước khi sửa code: đọc toàn bộ file, đối chiếu phần của mình với source/branch hiện tại.
Sau khi làm: chỉ thay nội dung giữa marker bắt đầu/kết thúc của mình bằng bản bàn giao mới nhất, không nối dài lịch sử. Giữ nguyên hai marker và sáu phần khác. Đọc lại file mới nhất ngay trước khi lưu để không ghi đè thay đổi của người khác.
Bản mới phải giữ tóm tắt phần đã xong còn liên quan, lỗi/dependency chưa xử lý và bước tiếp tục. Không lưu secret/token/password hay tự ghi PASS khi chưa test.
Nếu phiên bị dừng giữa chừng, cập nhật phần của mình với thay đổi dở dang để phiên sau biết.

Contract hướng dẫn hiện tại: LM-1.1.1.
Khởi tạo file này không có nghĩa tính năng của bất kỳ thành viên nào đã hoàn thành. Các phần chưa có bàn giao phải kiểm tra source thực tế.

===== NGUOI 1 - Dương Phúc Khang =====
Cập nhật 2026-11-01. Server f3fd74d, Android 8063704 đã pull; chưa commit/push các thay đổi hôm nay theo yêu cầu.
Phạm vi Khang: Book và đăng ký/đăng nhập/đăng xuất; Identity Java 21/Spring Boot, SQLite, BCrypt, RSA JWT, refresh rotation và throttling giữ nguyên.
Luồng mặc định mới: Flutter Windows/Android -> API Gateway 8080 -> Eureka 8761 -> Identity 8081 hoặc Catalog 8082. Gateway định tuyến, các service chạy thành tiến trình riêng.
Android: thêm core/config/api_config.dart để mặc định Windows dùng 127.0.0.1:8080, emulator dùng 10.0.2.2:8080. AuthConfig và ApiClient.catalogDio dùng Gateway; vẫn hỗ trợ API_BASE_URL/AUTH_BASE_URL/CATALOG_API_URL.
Server: Catalog bật Eureka; CatalogServiceApplication dùng ApplicationHome để tìm đúng data/catalog.db cả khi chạy executable jar. Đã xác nhận jar tự tìm đúng database mà không cần DB_PATH.
Kiểm chứng hôm nay: build 4 service thành công với JDK 21; Flutter Windows debug build thành công; analyze file thay đổi không lỗi; 11/11 Flutter tests pass gồm live register/login/restore/refresh/logout qua Gateway, live BookRemoteDataSource list/detail qua Gateway và UI auth/book tests. Gateway trả HTTP 200, 5 sách SQLite. Live book test gọi remote trực tiếp để không bị cơ chế fallback JSON che lỗi API.
Chạy thử hôm nay theo yêu cầu: ngầm, không GUI; không xác nhận thao tác tay trên cửa sổ Windows. Các lần sau chạy bình thường bằng flutter run -d windows.
Service đang chạy ngầm: Discovery PID 3448, Identity PID 5156, Gateway PID 4600, Catalog PID 2652. Log trong target/live-run.log và target/live-error.log của mỗi service. Cổng có thể thay đổi trạng thái khi tiến trình dừng; kiểm tra trước khi chạy lại.
Lưu ý local: renting-sevice/pom.xml là thay đổi có sẵn trước pull, đã bảo toàn. identity-service/data/identity.db đổi do tạo tài khoản live test auth-check-...@example.com. Không reset database. BookRepository còn fallback JSON khi DioException; không suy từ việc UI có sách rằng API luôn hoạt động.
Giới hạn: chưa kiểm chứng nghiệp vụ của thành viên khác, chưa bảo đảm revocation/quyền trên toàn bộ domain services. Chỉ commit/push khi người dùng yêu cầu.
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

