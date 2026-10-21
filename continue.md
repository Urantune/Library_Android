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
Mốc khoảng 50% theo 8/16 task, không phải phần trăm điểm chấm hay end-to-end production.
PRM-011/012/013: demo-ready. Sách list/detail có phân trang/search/retry; form thêm/sửa validate required/year/stock; giữ fake urantune.json, mapper API riêng, chưa gọi server.
MSS-009/010/011/012/013: API local verified. UUID String, Flyway migration Book, UTC TEXT Book-only converter; GET list/detail, POST create, PUT metadata, DELETE soft INACTIVE; check ISBN duplicate và field errors.
Phạm vi đã thu lại đúng yêu cầu: code Author/Category/Publisher và repositories + TimestampedEntity shared được hoàn nguyên đúng baseline 0d99ca2. Book mapper trả publisher/authors/categories=null, không đọc domain khác. Không cập nhật liên kết cũ; publisher_id chỉ đọc từ Book. Nonempty references khi ghi trả 409 RELATION_NOT_READY để không âm thầm bỏ dữ liệu.
Android JSON: ghi file tạm rồi rename; cache chỉ cập nhật sau khi lưu thành công; serialize các mutation; lỗi file/trùng ISBN/corrupt JSON hiển thị thay vì báo thành công giả.
Hàm chính: BookReadService.list/detail; BookWriteService.create/update/deactivate; BookMapper.toResponse; BookLocalDataSource createBook/updateBook/deleteBook; BookPage.fromBooks; BookDto.toDomain.
Kiểm chứng: Maven catalog-service test 14 passed trên SQLite thật (13 book + 1 context), bao gồm quan hệ cũ được giữ nguyên khi sửa metadata. Flutter test test/features/books 22 passed; analyze lib/features/books test/features/books no issues.
Git: Android 1514c76; code Server c6025f7, trạng thái mới nhất nằm ở commit bàn giao hiện tại. Tổng đợt này 6 commit, dưới giới hạn 14; tên bắt đầu bằng hai chữ hoa. Email author khangphucmn@outlook.com. Người dùng đã cho phép tiếp tục Git.
Chưa làm/không nhận hoàn tất: auth/gateway/RBAC, Redis, Kafka, search/filter server MSS-040, remote repository tích hợp, Swagger toàn service. Không coi direct APIs là đã bảo vệ quyền; chỉ local dev đến khi owner security tích hợp.
MSS local sạch, nhánh/upstream Server; không còn Dart/pubspec/Flutter. Android local nhánh/upstream Android. Pull ff-only để tránh tự merge nhầm. Backup bị trộn đã vào Recycle Bin; hai worktree tạm khang-android/server-history-merge đã dọn sau khi xác nhận không chứa code chưa lưu. Các thay đổi local có từ trước ở LibPRM được giữ nguyên.
Bước sau: tiếp tục đúng task Khang còn lại khi được giao; chỉ kết nối quan hệ khi owner domain sẵn. Bản bàn giao này được commit/push lên Server; không cần làm lại phần đã kiểm chứng để tăng số commit.
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

