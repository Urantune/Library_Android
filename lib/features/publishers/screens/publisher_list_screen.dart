import 'package:flutter/material.dart';

import '../models/publisher.dart';
import '../services/publisher_service.dart';
import 'publisher_detail_screen.dart';

// PRM-023: XEM DANH SÁCH NHÀ XUẤT BẢN
// =====================================================

// StatefulWidget được sử dụng vì màn hình có dữ liệu
// thay đổi theo kết quả trả về từ Backend.
class PublisherListScreen extends StatefulWidget {
  const PublisherListScreen({super.key});

  @override
  State<PublisherListScreen> createState() => _PublisherListScreenState();
}

class _PublisherListScreenState extends State<PublisherListScreen> {
  // Khởi tạo PublisherService để gọi API Backend.
  final PublisherService service = PublisherService();

  // Future lưu kết quả lấy danh sách nhà xuất bản.
  // late: Chưa cần gán giá trị ngay khi khai báo.Sẽ được khởi tạo trong initState().
  late Future<List<Publisher>> publishersFuture;

  // ===================================================
  // METHOD 1: INIT STATE
  // ===================================================

  @override
  void initState() {
    super.initState();

    // Khi màn hình được khởi tạo,
    // gọi API để lấy danh sách nhà xuất bản. Kết quả được lưu vào publishersFuture.
    publishersFuture = service.getPublishers();
  }

  // ===================================================
  // METHOD 2: REFRESH PUBLISHERS
  // ===================================================

  // Hàm tải lại danh sách nhà xuất bản.
  Future<void> refreshPublishers() async {
    // Gọi lại API GET danh sách.
    final future = service.getPublishers();

    // setState thông báo Flutter rằng dữ liệu Future
    // đã thay đổi và cần cập nhật giao diện.
    //
    // FutureBuilder sẽ nhận Future mới và tải lại dữ liệu.
    setState(() {
      publishersFuture = future;
    });

    try {
      // Chờ API hoàn thành.
      await future;
    } catch (_) {
      // Nếu API lỗi, không xử lý trực tiếp ở đây.
      // FutureBuilder sẽ nhận lỗi và hiển thị Error UI.
    }
  }

  // ===================================================
  // METHOD 3: OPEN DETAIL
  // ===================================================

  // Mở màn hình chi tiết của nhà xuất bản được chọn.
  // Tham số id là mã nhà xuất bản.
  void openDetail(int id) {
    // Navigator.push dùng để chuyển sang màn hình mới.
    Navigator.push(
      context,
      // MaterialPageRoute tạo trang mới theo hiệu ứng điều hướng Material Design.
      MaterialPageRoute(
        // Truyền ID nhà xuất bản sang Detail Screen.
        builder: (context) {
          return PublisherDetailScreen(
            publisherId: id,
          );
        },
      ),
    );
  }

  // ===================================================
  // METHOD 4: BUILD GIAO DIỆN
  // ===================================================

  @override
  Widget build(BuildContext context) {
    // Container là widget bao ngoài màn hình.
    return Container(
      // Màu nền màn hình.
      color: const Color(0xFFF5F7FB),

      // Column sắp xếp các widget theo chiều dọc.
      child: Column(
        children: [
          // =============================================
          // HEADER: TIÊU ĐỀ VÀ NÚT REFRESH
          // =============================================

          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Expanded chiếm phần không gian còn lại.
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề màn hình.
                      Text(
                        'Nhà xuất bản',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),

                      SizedBox(height: 5),

                      // Mô tả chức năng.
                      Text(
                        'Quản lý danh sách nhà xuất bản',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Nút tải lại danh sách.
                // Khi nhấn sẽ gọi refreshPublishers().
                IconButton(
                  onPressed: refreshPublishers,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          // =============================================
          // DANH SÁCH NHÀ XUẤT BẢN
          // =============================================

          // Expanded giúp danh sách chiếm toàn bộ không gian còn lại của Column.
          Expanded(
            // FutureBuilder theo dõi Future lấy dữ liệu.
            //
            // Khi Future thay đổi trạng thái, FutureBuilder tự động xây dựng lại giao diện.
            child: FutureBuilder<List<Publisher>>(
              // Future chứa danh sách đang được tải.
              future: publishersFuture,

              // builder nhận snapshot chứa trạng thái và dữ liệu trả về từ Future.
              builder: (context, snapshot) {
                // =======================================
                // TRƯỜNG HỢP 1: ĐANG TẢI DỮ LIỆU
                // =======================================

                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Hiển thị vòng tròn Loading.
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // =======================================
                // TRƯỜNG HỢP 2: API XẢY RA LỖI
                // =======================================

                if (snapshot.hasError) {
                  // Hiển thị thông báo lỗi
                  // và nút cho phép thử lại.
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
                        ),

                        const SizedBox(height: 10),

                        // Nhấn nút để gọi lại API.
                        ElevatedButton(
                          onPressed: refreshPublishers,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                // =======================================
                // TRƯỜNG HỢP 3: LẤY DỮ LIỆU THÀNH CÔNG
                // =======================================

                // Lấy danh sách từ snapshot.
                //
                // Nếu không có dữ liệu thì mặc định sử dụng một danh sách rỗng.
                final publishers = snapshot.data ?? [];

                // =======================================
                // TRƯỜNG HỢP 4: DANH SÁCH TRỐNG
                // =======================================
                if (publishers.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có nhà xuất bản',
                    ),
                  );
                }

                // =======================================
                // TRƯỜNG HỢP 5: HIỂN THỊ DANH SÁCH
                // =======================================
                // RefreshIndicator cho phép người dùng kéo xuống để tải lại danh sách.
                return RefreshIndicator(
                  // Khi kéo xuống, gọi API tải lại.
                  onRefresh: refreshPublishers,

                  // ListView.builder tạo danh sách cuộn.
                  //
                  // builder chỉ xây dựng các phần tử cần thiết khi hiển thị.
                  child: ListView.builder(
                    // Cho phép kéo xuống kể cả khi danh sách không đủ dài để cuộn.
                    physics: const AlwaysScrollableScrollPhysics(),

                    padding: const EdgeInsets.all(16),

                    // Số lượng phần tử trong danh sách.
                    itemCount: publishers.length,

                    // Xây dựng từng nhà xuất bản.
                    itemBuilder: (context, index) {
                      // Lấy nhà xuất bản tại vị trí index.
                      final publisher = publishers[index];

                      // Mỗi nhà xuất bản được hiển thị dưới dạng một Card.
                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          // Icon đại diện nhà xuất bản.
                          leading: const CircleAvatar(
                            child: Icon(Icons.apartment),
                          ),

                          // Hiển thị tên nhà xuất bản.
                          title: Text(
                            publisher.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // Hiển thị địa chỉ.
                          // Nếu địa chỉ rỗng thì hiển thị thông báo Chưa có địa chỉ.
                          subtitle: Text(
                            publisher.address.isEmpty
                                ? 'Chưa có địa chỉ'
                                : publisher.address,
                          ),

                          // Icon chỉ dẫn có thể mở chi tiết.
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),

                          // Khi nhấn vào Card,
                          // gọi openDetail và truyền ID.
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
