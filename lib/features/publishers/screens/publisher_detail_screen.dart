import 'package:flutter/material.dart';

import '../models/publisher.dart';
import '../services/publisher_service.dart';

// Màn hình hiển thị chi tiết của một Nhà xuất bản.
// Màn hình này nhận vào publisherId từ màn hình danh sách.
// Sau đó dùng PublisherService để lấy dữ liệu chi tiết theo ID đó.
// Luồng:
// PublisherListScreen
//        ↓
// truyền publisherId
//        ↓
// PublisherDetailScreen
//        ↓
// gọi getPublisherById(id)
//        ↓
// nhận Publisher
//        ↓
// hiển thị thông tin lên UI
class PublisherDetailScreen extends StatefulWidget {
  // ID của nhà xuất bản được chọn từ màn hình danh sách. / click vào NXB có id = 2 -> thì PublisherDetailScreen sẽ nhận publisherId = 2.
  final int publisherId;

  // Constructor của màn hình.
  // required this.publisherId: bắt buộc màn hình trước phải truyền ID sang.
  const PublisherDetailScreen({
    super.key,
    required this.publisherId,
  });

  @override
  State<PublisherDetailScreen> createState() => _PublisherDetailScreenState();
}

// State của PublisherDetailScreen.
// Dùng StatefulWidget vì màn hình có dữ liệu bất đồng bộ:
// ban đầu chưa có dữ liệu,
// sau đó dữ liệu được tải từ JSON/API rồi UI mới hiển thị.
class _PublisherDetailScreenState extends State<PublisherDetailScreen> {
  // Tạo PublisherService để gọi hàm lấy dữ liệu Nhà xuất bản.
  // Service chịu trách nhiệm xử lý nguồn dữ liệu:
  // - fake JSON
  // - hoặc API thật
  // UI không cần biết dữ liệu đến từ đâu.
  final PublisherService _publisherService = PublisherService();

  // Future dùng để lưu kết quả lấy chi tiết Nhà xuất bản.
  // Future<Publisher> nghĩa là: hiện tại chưa có Publisher ngay, nhưng trong tương lai sẽ trả về một Publisher.
  // late:
  // biến sẽ được gán giá trị sau, cụ thể là trong initState().
  late Future<Publisher> _publisherFuture;

  @override
  void initState() {
    super.initState();

    // initState() chỉ chạy một lần khi màn hình được tạo.
    // Đây là nơi phù hợp để gọi API / đọc dữ liệu, tránh việc gọi lại nhiều lần mỗi khi build() chạy.
    // widget.publisherId:
    // lấy ID đã được truyền vào PublisherDetailScreen.
    // getPublisherById():
    // tìm đúng Nhà xuất bản có ID tương ứng.
    _publisherFuture = _publisherService.getPublisherById(
      widget.publisherId,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold tạo khung giao diện cơ bản của màn hình:
    // - AppBar
    // - Body
    return Scaffold(
      // Thanh tiêu đề phía trên.
      appBar: AppBar(
        title: const Text(
          'Chi tiết nhà xuất bản',
        ),
      ),

      // FutureBuilder dùng để theo dõi trạng thái của Future.
      // Trong trường hợp này:
      // FutureBuilder đang chờ _publisherFuture hoàn thành.
      // Nó giúp UI xử lý các trạng thái:
      // 1. Loading
      // 2. Error
      // 3. Success
      body: FutureBuilder<Publisher>(
        // Future cần theo dõi.
        future: _publisherFuture,

        // builder sẽ được gọi lại khi trạng thái Future thay đổi.
        // snapshot chứa:
        // - trạng thái hiện tại
        // - dữ liệu nếu thành công
        // - lỗi nếu thất bại
        builder: (context, snapshot) {
          // TRẠNG THÁI 1: LOADING
          // =========================
          // Nếu Future vẫn đang chạy,
          // nghĩa là dữ liệu chưa tải xong.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              // Hiển thị vòng tròn loading
              // để người dùng biết app đang xử lý dữ liệu.
              child: CircularProgressIndicator(),
            );
          }

          // TRẠNG THÁI 2: ERROR
          // =========================
          // Nếu quá trình lấy dữ liệu xảy ra lỗi.
          //
          // Ví dụ:
          // - không tìm thấy ID
          // - API lỗi
          // - mất kết nối
          // - JSON sai cấu trúc
          if (snapshot.hasError) {
            return Center(
              child: Text(
                // snapshot.error chứa thông tin lỗi
                // được throw từ PublisherService.
                snapshot.error.toString(),
              ),
            );
          }

          // TRẠNG THÁI 3: SUCCESS
          // =========================
          // Lấy Publisher từ Future.
          // snapshot.data có kiểu Publisher?
          // nên nó có thể null.
          final publisher = snapshot.data;

          // Kiểm tra phòng trường hợp dữ liệu không tồn tại.
          if (publisher == null) {
            return const Center(
              child: Text(
                'Không tìm thấy nhà xuất bản',
              ),
            );
          }

          // Nếu đến đây nghĩa là:
          // - Future đã hoàn thành
          // - không có lỗi
          // - đã có dữ liệu Publisher
          // Bắt đầu hiển thị chi tiết Nhà xuất bản.
          return Padding(
            // Tạo khoảng cách 24px xung quanh nội dung.
            padding: const EdgeInsets.all(24),

            child: Column(
              // Căn toàn bộ nội dung về bên trái.
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // TÊN NHÀ XUẤT BẢN
                // =========================

                Text(
                  // Lấy tên từ object Publisher.
                  publisher.name,

                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Tạo khoảng cách dọc 24px.
                const SizedBox(height: 24),

                // ID
                // =========================

                Text(
                  // ${publisher.id}    là String Interpolation trong Dart.
                  // Ví dụ:
                  // publisher.id = 1
                  // kết quả: "Mã NXB: 1"
                  'Mã NXB: ${publisher.id}',
                ),

                const SizedBox(height: 12),

                // ĐỊA CHỈ
                // =========================

                Text(
                  'Địa chỉ: ${publisher.address}',
                ),

                const SizedBox(height: 12),

                // SỐ ĐIỆN THOẠI
                // =========================

                Text(
                  'Điện thoại: ${publisher.phone}',
                ),

                const SizedBox(height: 12),

                // EMAIL
                // =========================

                Text(
                  'Email: ${publisher.email}',
                ),

                const SizedBox(height: 12),

                // MÔ TẢ
                // =========================

                Text(
                  'Mô tả: ${publisher.description}',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
