import 'package:flutter/material.dart';

import '../models/publisher.dart';
import '../services/publisher_service.dart';

/// Nguyen Duy Khang - CE192012
/// Màn hình hiển thị chi tiết thông tin nhà xuất bản (PRM-023: Xem chi tiết theo ID)
class PublisherDetailScreen extends StatefulWidget {
  final String publisherId; // ID nhà xuất bản cần truy vấn chi tiết

  const PublisherDetailScreen({
    super.key,
    required this.publisherId,
  });

  @override
  State<PublisherDetailScreen> createState() => _PublisherDetailScreenState();
}

/// Nguyen Duy Khang - CE192012
/// State quản lý việc gọi API lấy thông tin chi tiết và hiển thị dữ liệu nhà xuất bản
class _PublisherDetailScreenState extends State<PublisherDetailScreen> {
  // Service gọi API nhà xuất bản
  final PublisherService service = PublisherService();

  // Biến lưu Future chứa dữ liệu chi tiết nhà xuất bản tải từ API
  late Future<Publisher> publisherFuture;

  @override
  void initState() {
    super.initState();
    // Gọi API lấy dữ liệu chi tiết nhà xuất bản theo publisherId truyền vào (PRM-023)
    publisherFuture = service.getPublisherById(
      widget.publisherId,
    );
  }

  /// Tải lại thông tin chi tiết của nhà xuất bản từ Backend
  void refreshPublisher() {
    setState(() {
      publisherFuture = service.getPublisherById(
        widget.publisherId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Chi tiết nhà xuất bản'),
        actions: [
          // Nút làm mới dữ liệu chi tiết
          IconButton(
            onPressed: refreshPublisher,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: FutureBuilder<Publisher>(
        future: publisherFuture,
        builder: (context, snapshot) {
          // TRẠNG THÁI 1: ĐANG TẢI DỮ LIỆU
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // TRẠNG THÁI 2: XẢY RA LỖI KHI GỌI API
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
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: refreshPublisher,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final publisher = snapshot.data;

          // TRẠNG THÁI 3: KHÔNG TÌM THẤY DỮ LIỆU
          if (publisher == null) {
            return const Center(
              child: Text('Không tìm thấy nhà xuất bản'),
            );
          }

          // TRẠNG THÁI 4: HIỂN THỊ CÁC THÔNG TIN CHI TIẾT CỦA NHÀ XUẤT BẢN (PRM-023)
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Biểu tượng đại diện
                    const Center(
                      child: Icon(
                        Icons.apartment,
                        size: 65,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tên nhà xuất bản
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
                    const Divider(height: 35),
                    // Danh sách các thông tin chi tiết
                    buildInfo(
                      'Mã nhà xuất bản',
                      publisher.id,
                    ),
                    buildInfo(
                      'Tên nhà xuất bản',
                      publisher.name,
                    ),
                    buildInfo(
                      'Địa chỉ',
                      publisher.address,
                    ),
                    buildInfo(
                      'Số điện thoại',
                      publisher.phone,
                    ),
                    buildInfo(
                      'Email',
                      publisher.email,
                    ),
                    buildInfo(
                      'Website',
                      publisher.website,
                    ),
                    buildInfo(
                      'Trạng thái',
                      publisher.status,
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

  /// Widget phụ trợ hiển thị một dòng thông tin gồm Tiêu đề và Nội dung
  Widget buildInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
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
