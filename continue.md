# Continue — trạng thái mới nhất của 7 thành viên

File này thuộc gốc MSS, cùng cấp các thư mục services. File tổng và file cá nhân được gửi qua chat; không cần chép hai file hướng dẫn vào đây.

Trước khi sửa code: đọc toàn bộ file, đối chiếu phần của mình với source/branch hiện tại.
Sau khi làm: chỉ thay nội dung giữa marker bắt đầu/kết thúc của mình bằng bản bàn giao mới nhất, không nối dài lịch sử. Giữ nguyên hai marker và sáu phần khác. Đọc lại file mới nhất ngay trước khi lưu để không ghi đè thay đổi của người khác.
Bản mới phải giữ tóm tắt phần đã xong còn liên quan, lỗi/dependency chưa xử lý và bước tiếp tục. Không lưu secret/token/password hay tự ghi PASS khi chưa test.
Nếu phiên bị dừng giữa chừng, cập nhật phần của mình với thay đổi dở dang để phiên sau biết.

Contract hướng dẫn hiện tại: LM-1.1.1.
Khởi tạo file này không có nghĩa tính năng của bất kỳ thành viên nào đã hoàn thành. Các phần chưa có bàn giao phải kiểm tra source thực tế.

===== NGUOI 1 - Dương Phúc Khang =====
Cập nhật 2026-11-04. Đã fetch và fast-forward nhánh Server từ 6dba59e lên 3e05b03, giữ các commit Category mới trên remote.
Phạm vi phiên này: bỏ module legacy renting-sevice vì không thuộc kiến trúc 7 service; mượn/trả dùng circulation-service. Đã bỏ module khỏi parent pom, cập nhật README và xóa thư mục renting-sevice.
Database theo blueprint: identity-service/data/identity.db, catalog-service/data/catalog.db, circulation-service/data/circulation.db, reservation-service/data/reservation.db, notification-service/data/notification.db đều đã có và được Git theo dõi. Discovery và Gateway không cần SQLite. Không tạo thêm DB.
Thay đổi local có sẵn cần giữ ngoài phần xóa: identity-service/data/identity.db do live test; file lock Word tạm ở repo root. Thay đổi renting-sevice/pom.xml bị xóa cùng module theo yêu cầu xóa service.
Kiểm chứng và bước tiếp: xác nhận parent pom/README không còn module legacy; commit và push riêng phần xóa lên Server.
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

