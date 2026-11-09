import 'package:flutter/material.dart';

import '../models/publisher.dart';
import '../services/publisher_service.dart';
import 'publisher_add_screen.dart';
import 'publisher_detail_screen.dart';

/// Nguyen Duy Khang - CE192012
/// Màn hình quản lý danh sách nhà xuất bản (PRM-023: Hiển thị danh sách, PRM-024: Điều hướng thêm mới)
class PublisherListScreen extends StatefulWidget {
  const PublisherListScreen({super.key});

  @override
  State<PublisherListScreen> createState() => _PublisherListScreenState();
}

/// Nguyen Duy Khang - CE192012
/// State quản lý vòng đời và trạng thái hiển thị của màn hình danh sách nhà xuất bản
class _PublisherListScreenState extends State<PublisherListScreen> {
  // Service gọi API nhà xuất bản
  final PublisherService service = PublisherService();

  // Biến lưu trữ Future chứa danh sách nhà xuất bản tải từ API
  late Future<List<Publisher>> publishersFuture;

  @override
  void initState() {
    super.initState();
    // Tự động gọi API lấy danh sách nhà xuất bản khi khởi tạo màn hình (PRM-023)
    publishersFuture = service.getPublishers();
  }

  /// Tải lại danh sách nhà xuất bản từ Backend (dùng cho pull-to-refresh và nút reload)
  Future<void> refreshPublishers() async {
    final future = service.getPublishers();

    setState(() {
      publishersFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // Lỗi sẽ được FutureBuilder bắt và hiển thị giao diện phù hợp
    }
  }

  /// PRM-024: Chuyển sang màn hình thêm mới nhà xuất bản; reload danh sách nếu tạo thành công
  void openAddPublisher() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const PublisherAddScreen(),
      ),
    ).then((created) {
      if (created == true) {
        // Tải lại danh sách ngay lập tức khi thêm thành công
        refreshPublishers();
      }
    });
  }

  /// PRM-023: Chuyển sang màn hình chi tiết nhà xuất bản dựa theo ID được chọn
  void openDetail(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return PublisherDetailScreen(
            publisherId: id,
          );
        },
      ),
    ).then((_) {
      // Tải lại dữ liệu khi quay về để đảm bảo cập nhật nếu có thay đổi
      refreshPublishers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      // Nút Floating Action Button tiện lợi để thêm mới nhà xuất bản (PRM-024)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddPublisher,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm NXB',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF0878F9),
      ),
      body: Column(
        children: [
          // KHU VỰC TIÊU ĐỀ VÀ CÁC NÚT THAO TÁC TRÊN ĐẦU
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhà xuất bản',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Quản lý danh sách nhà xuất bản',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Nút Thêm mới ở thanh tiêu đề (PRM-024)
                FilledButton.icon(
                  onPressed: openAddPublisher,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Thêm mới',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0878F9),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Nút Tải lại danh sách (Refresh)
                IconButton(
                  onPressed: refreshPublishers,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Tải lại',
                ),
              ],
            ),
          ),

          // KHU VỰC HIỂN THỊ DANH SÁCH (DÙNG FUTUREBUILDER LẮNG NGHE DỮ LIỆU TỪ API - PRM-023)
          Expanded(
            child: FutureBuilder<List<Publisher>>(
              future: publishersFuture,
              builder: (context, snapshot) {
                // TRẠNG THÁI 1: ĐANG TẢI DỮ LIỆU
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // TRẠNG THÁI 2: GẶP LỖI KHI GỌI API
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
                          'Không thể tải danh sách',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: refreshPublishers,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                // LẤY DỮ LIỆU DANH SÁCH THỰC TẾ TỪ RESPONSE
                final publishers = snapshot.data ?? [];

                // TRẠNG THÁI 3: DANH SÁCH TRỐNG
                if (publishers.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có nhà xuất bản nào.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // TRẠNG THÁI 4: HIỂN THỊ DANH SÁCH (CÓ HỖ TRỢ KÉO ĐỂ TẢI LẠI - PULL TO REFRESH)
                return RefreshIndicator(
                  onRefresh: refreshPublishers,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: publishers.length,
                    itemBuilder: (context, index) {
                      final publisher = publishers[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.apartment),
                          ),
                          title: Text(
                            publisher.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            publisher.address.isEmpty
                                ? 'Chưa có địa chỉ'
                                : publisher.address,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          // Chạm vào item để xem chi tiết nhà xuất bản (PRM-023)
                          onTap: () {
                            openDetail(publisher.id);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
