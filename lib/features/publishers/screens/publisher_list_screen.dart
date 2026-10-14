import 'package:flutter/material.dart';

import '../models/publisher.dart'; // Import model Publisher để sử dụng kiểu dữ liệu Publisher.
import '../services/publisher_service.dart'; // Import service để lấy danh sách Nhà xuất bản từ fake JSON hoặc API backend.
import 'publisher_detail_screen.dart'; // Khi người dùng bấm vào một Nhà xuất bản, app sẽ chuyển sang PublisherDetailScreen.

// Màn hình hiển thị danh sách Nhà xuất bản.
// Dùng StatefulWidget vì dữ liệu có thể thay đổi:
// - Ban đầu đang loading.
// - Sau khi lấy dữ liệu xong thì hiển thị danh sách.
// - Người dùng có thể bấm refresh để tải lại dữ liệu.
class PublisherListScreen extends StatefulWidget {
  const PublisherListScreen({super.key});

  @override
  State<PublisherListScreen> createState() => _PublisherListScreenState();
}

// State chứa dữ liệu và logic của PublisherListScreen.
class _PublisherListScreenState extends State<PublisherListScreen> {
  // Tạo một PublisherService.
  // PublisherService chịu trách nhiệm lấy dữ liệu từ:
  // - file fake JSON trong assets
  // - hoặc API backend
  // UI chỉ cần gọi service, không cần biết dữ liệu thực tế đến từ đâu.
  final PublisherService _publisherService = PublisherService();

  // Future chứa kết quả danh sách Nhà xuất bản.
  // Future<List<Publisher>> nghĩa là:
  // dữ liệu chưa có ngay lập tức, nhưng sau một khoảng thời gian sẽ trả về một List<Publisher>.
  // late: biến chưa được gán ngay khi khai báo, mà sẽ được gán trong initState().
  late Future<List<Publisher>> _publishersFuture;

  // initState() chạy một lần
  // khi màn hình PublisherListScreen được tạo.
  @override
  void initState() {
    super.initState();

    // Gọi hàm load dữ liệu ngay khi mở màn hình.
    _loadPublishers();
  }

  // Hàm dùng để lấy danh sách Nhà xuất bản.
  // Không gọi service trực tiếp trong build() để tránh việc Flutter rebuild UI
  // rồi gọi API / đọc JSON nhiều lần không cần thiết.
  void _loadPublishers() {
    _publishersFuture = _publisherService.getPublishers();
  }

  // Hàm dùng để tải lại danh sách.
  // setState(): báo cho Flutter rằng dữ liệu/state đã thay đổi và UI cần được build lại.
  void _refreshPublishers() {
    setState(() {
      // Tạo Future mới để lấy lại dữ liệu.
      _loadPublishers();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Không dùng Scaffold ở đây vì PublisherListScreen đang được nhúng bên trong DashboardPage.
    // DashboardPage đã có:
    // - Sidebar
    // - TopBar
    // - Scaffold chính
    // Vì vậy màn hình Publisher chỉ trả về phần nội dung.
    return Container(
      // Màu nền giống background chung của Dashboard.
      color: const Color(0xFFF5F7FB),

      child: Column(
        // Căn các widget con về bên trái.
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // HEADER
          // ==================================================
          Padding(
            // Khoảng cách:
            // left = 24
            // top = 24
            // right = 24
            // bottom = 12
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              12,
            ),

            child: Row(
              children: [
                // Expanded giúp phần tiêu đề
                // chiếm toàn bộ không gian còn lại,
                // để nút refresh nằm ở bên phải.
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề chính của màn hình.
                      Text(
                        'Nhà xuất bản',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),

                      // Khoảng cách giữa title và subtitle.
                      SizedBox(height: 4),

                      // Mô tả ngắn của màn hình.
                      Text(
                        'Danh sách nhà xuất bản trong hệ thống',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Nút refresh ở góc phải.
                IconButton(
                  // Tooltip hiển thị khi hover chuột.
                  tooltip: 'Tải lại',

                  // Khi bấm nút refresh
                  // thì gọi lại _refreshPublishers().
                  onPressed: _refreshPublishers,

                  icon: const Icon(
                    Icons.refresh,
                  ),
                ),
              ],
            ),
          ),

          // KHU VỰC DANH SÁCH
          // ==================================================

          // Expanded giúp danh sách chiếm toàn bộ
          // chiều cao còn lại của màn hình.
          Expanded(
            // FutureBuilder kết nối dữ liệu Future với giao diện Flutter.
            // Nó theo dõi _publishersFuture và rebuild UI khi Future thay đổi trạng thái.
            child: FutureBuilder<List<Publisher>>(
              // Future cần theo dõi.
              future: _publishersFuture,

              // snapshot chứa:
              // - trạng thái Future
              // - dữ liệu
              // - lỗi nếu có
              builder: (context, snapshot) {
                // TRẠNG THÁI 1: LOADING
                // ==================================================

                // Nếu Future vẫn chưa hoàn thành.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Hiển thị vòng tròn loading.
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // TRẠNG THÁI 2: ERROR
                // ==================================================

                // Nếu getPublishers() throw Exception hoặc có lỗi đọc JSON / gọi API.
                if (snapshot.hasError) {
                  // Gọi widget riêng để hiển thị lỗi.
                  return _buildError(
                    snapshot.error.toString(),
                  );
                }

                // TRẠNG THÁI 3: SUCCESS
                // ==================================================

                // Nếu snapshot.data có dữ liệu thì gán vào publishers.
                // Nếu snapshot.data == null thì dùng danh sách rỗng [].
                final publishers = snapshot.data ?? [];

                // EMPTY STATE
                // ==================================================

                // Nếu server / JSON trả về danh sách rỗng.
                if (publishers.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có nhà xuất bản',
                    ),
                  );
                }

                // HIỂN THỊ DANH SÁCH
                // ==================================================

                // RefreshIndicator cho phép kéo xuống để refresh danh sách trên mobile.
                return RefreshIndicator(
                  // Khi người dùng kéo xuống refresh.
                  onRefresh: () async {
                    // Gọi lại dữ liệu.
                    _refreshPublishers();

                    // Chờ Future mới tải xong.
                    await _publishersFuture;
                  },

                  // ListView.builder dùng để render danh sách.
                  // Ưu điểm:
                  // chỉ tạo item khi cần hiển thị,
                  // phù hợp với danh sách lớn.
                  child: ListView.builder(
                    // Khoảng cách xung quanh danh sách.
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      8,
                      24,
                      24,
                    ),

                    // Tổng số item cần hiển thị.
                    itemCount: publishers.length,

                    // itemBuilder chạy cho từng phần tử.
                    itemBuilder: (context, index) {
                      // Lấy Publisher tại vị trí index.
                      final publisher = publishers[index];

                      // Gọi widget riêng
                      // để vẽ card của từng Publisher.
                      return _buildPublisherCard(
                        publisher,
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

  // WIDGET CARD NHÀ XUẤT BẢN
  // ==================================================

  // Hàm nhận một Publisher và trả về widget Card tương ứng.
  //
  // Tách thành hàm riêng giúp:
  // - code build() gọn hơn
  // - dễ đọc
  // - dễ sửa giao diện item sau này
  Widget _buildPublisherCard(
    Publisher publisher,
  ) {
    return Card(
      // Khoảng cách phía dưới giữa các card.
      margin: const EdgeInsets.only(bottom: 12),

      // elevation = 0:
      // không dùng bóng mặc định của Card.
      elevation: 0,

      // Thiết lập hình dạng và border.
      shape: RoundedRectangleBorder(
        // Bo góc card.
        borderRadius: BorderRadius.circular(12),

        // Viền card.
        side: const BorderSide(
          color: Color(0xFFE8ECF3),
        ),
      ),

      // Màu nền của card.
      color: Colors.white,

      // ListTile tiện cho UI dạng:
      // icon | title + subtitle | arrow
      child: ListTile(
        // Padding bên trong ListTile.
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),

        // ICON BÊN TRÁI
        // ==================================================

        leading: Container(
          width: 45,
          height: 45,

          decoration: BoxDecoration(
            // Màu xanh với độ trong suốt 10%.
            color: const Color(0xFF2563EB).withOpacity(0.10),

            borderRadius: BorderRadius.circular(10),
          ),

          // Icon đại diện cho Nhà xuất bản.
          child: const Icon(
            Icons.apartment_rounded,
            color: Color(0xFF2563EB),
          ),
        ),

        // TÊN NHÀ XUẤT BẢN
        // ==================================================

        title: Text(
          // Lấy name từ Publisher model.
          publisher.name,

          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),

        // ĐỊA CHỈ
        // ==================================================

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              // Icon địa chỉ.
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: Color(0xFF94A3B8),
              ),

              const SizedBox(width: 4),

              // Expanded để text địa chỉ
              // sử dụng phần chiều rộng còn lại.
              Expanded(
                child: Text(
                  // Nếu address là chuỗi rỗng,
                  // hiển thị "Chưa có địa chỉ".
                  publisher.address.isEmpty
                      ? 'Chưa có địa chỉ'
                      : publisher.address,

                  // Chỉ cho phép hiển thị 1 dòng.
                  maxLines: 1,

                  // Nếu địa chỉ quá dài,
                  // phần dư sẽ hiển thị bằng ...
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ICON MŨI TÊN BÊN PHẢI
        // ==================================================

        // Cho người dùng biết item có thể click để xem chi tiết.
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF94A3B8),
        ),

        // MỞ MÀN HÌNH CHI TIẾT
        // ==================================================

        onTap: () {
          // Navigator.push mở một màn hình mới và đặt nó lên navigation stack.
          Navigator.of(context).push(
            // MaterialPageRoute tạo route theo phong cách Material Design.
            MaterialPageRoute(
              // Tạo màn hình chi tiết.
              builder: (_) => PublisherDetailScreen(
                // Truyền ID của Publisher được người dùng click.
                // Ví dụ:
                // publisher.id = 2
                // thì DetailScreen nhận:
                // publisherId = 2
                publisherId: publisher.id,
              ),
            ),
          );
        },
      ),
    );
  }

  // ERROR UI
  // ==================================================

  // Widget riêng dùng để hiển thị lỗi.
  // error:
  // là nội dung Exception nhận từ FutureBuilder.
  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          // Chỉ chiếm không gian vừa đủ cho các widget con.
          mainAxisSize: MainAxisSize.min,

          children: [
            // Icon lỗi.
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),

            const SizedBox(height: 12),

            // Thông báo lỗi thân thiện.
            const Text(
              'Không thể tải danh sách nhà xuất bản',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Hiển thị chi tiết lỗi.
            // Ví dụ:
            // Unable to load asset... hoặc API status code 500...
            Text(
              error,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Nút cho phép người dùng thử tải lại.
            ElevatedButton.icon(
              onPressed: _refreshPublishers,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Thử lại',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
