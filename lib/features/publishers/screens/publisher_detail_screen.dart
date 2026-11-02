import 'package:flutter/material.dart';

import '../models/publisher.dart';
import '../services/publisher_service.dart';

// PRM-023: XEM CHI TIẾT NHÀ XUẤT BẢN
// =====================================================

class PublisherDetailScreen extends StatefulWidget {
  // ID được truyền từ PublisherListScreen.
  // Dùng ID này để gọi API lấy đúng nhà xuất bản.
  final int publisherId;

  // Constructor nhận publisherId.
  const PublisherDetailScreen({
    super.key,
    required this.publisherId,
  });

  @override
  State<PublisherDetailScreen> createState() => _PublisherDetailScreenState();
}

class _PublisherDetailScreenState extends State<PublisherDetailScreen> {
  // Khởi tạo Service để gọi API Backend.
  final PublisherService service = PublisherService();

  // Future lưu kết quả API chi tiết. Kiểu dữ liệu trả về là một Publisher.
  late Future<Publisher> publisherFuture;

  // ===================================================
  // METHOD 1: INIT STATE
  // ===================================================

  @override
  void initState() {
    super.initState();

    // Khi mở màn hình chi tiết, gọi API lấy thông tin nhà xuất bản.
    publisherFuture = service.getPublisherById(
      widget.publisherId,
    );
  }

  // ===================================================
  // METHOD 2: REFRESH PUBLISHER
  // ===================================================

  // Hàm tải lại thông tin chi tiết.
  void refreshPublisher() {
    // setState thông báo Flutter cập nhật giao diện.
    setState(() {
      // Gọi lại API với ID hiện tại.
      publisherFuture = service.getPublisherById(
        widget.publisherId,
      );
    });
  }

  // ===================================================
  // METHOD 3: BUILD GIAO DIỆN
  // ===================================================

  @override
  Widget build(BuildContext context) {
    // Scaffold tạo cấu trúc màn hình.
    return Scaffold(
      // Màu nền.
      backgroundColor: const Color(0xFFF5F7FB),

      // AppBar là thanh tiêu đề phía trên.
      appBar: AppBar(
        title: const Text('Chi tiết nhà xuất bản'),

        // Nút tải lại thông tin.
        actions: [
          IconButton(
            onPressed: refreshPublisher,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      // FutureBuilder theo dõi kết quả API.
      body: FutureBuilder<Publisher>(
        // Future chứa dữ liệu chi tiết.
        future: publisherFuture,

        // Xử lý các trạng thái của API.
        builder: (context, snapshot) {
          // ===========================================
          // TRẠNG THÁI 1: ĐANG TẢI
          // ===========================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ===========================================
          // TRẠNG THÁI 2: XẢY RA LỖI
          // ===========================================

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 45,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Không thể tải thông tin nhà xuất bản',
                  ),

                  const SizedBox(height: 10),

                  // Cho phép người dùng gọi lại API.
                  ElevatedButton(
                    onPressed: refreshPublisher,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          // ===========================================
          // TRẠNG THÁI 3: LẤY DỮ LIỆU THÀNH CÔNG
          // ===========================================

          // Lấy đối tượng Publisher từ snapshot.
          final publisher = snapshot.data;

          // Nếu không có dữ liệu thì thông báo.
          if (publisher == null) {
            return const Center(
              child: Text('Không tìm thấy nhà xuất bản'),
            );
          }

          // ===========================================
          // TRẠNG THÁI 4: HIỂN THỊ CHI TIẾT
          // ===========================================

          // SingleChildScrollView cho phép cuộn khi nội dung vượt quá chiều cao màn hình.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),

                // Column sắp xếp thông tin theo chiều dọc.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =================================
                    // ICON ĐẠI DIỆN
                    // =================================

                    const Center(
                      child: Icon(
                        Icons.apartment,
                        size: 65,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =================================
                    // TÊN NHÀ XUẤT BẢN
                    // =================================

                    Center(
                      child: Text(
                        publisher.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Đường phân cách.
                    const Divider(height: 35),

                    // =================================
                    // CÁC THÔNG TIN CHI TIẾT
                    // =================================

                    // Mã nhà xuất bản.
                    buildInfo(
                      'Mã nhà xuất bản',
                      publisher.id.toString(),
                    ),

                    // Tên nhà xuất bản.
                    buildInfo(
                      'Tên nhà xuất bản',
                      publisher.name,
                    ),

                    // Địa chỉ.
                    buildInfo(
                      'Địa chỉ',
                      publisher.address,
                    ),

                    // Số điện thoại.
                    buildInfo(
                      'Số điện thoại',
                      publisher.phone,
                    ),

                    // Email.
                    buildInfo(
                      'Email',
                      publisher.email,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===================================================
  // METHOD 4: BUILD INFO
  // ===================================================

  // Widget dùng chung để hiển thị từng dòng thông tin.
  //
  // title: Tên trường dữ liệu.
  // value: Giá trị tương ứng lấy từ Publisher Object.
  Widget buildInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị tên trường.
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 5),

          // Hiển thị giá trị.
          // Nếu giá trị rỗng thì thông báo nhà xuất bản chưa cập nhật thông tin.
          Text(
            value.isEmpty ? 'Chưa cập nhật' : value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
