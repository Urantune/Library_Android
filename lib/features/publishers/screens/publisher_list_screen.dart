import 'package:flutter/material.dart';

import '../models/publisher.dart';
import '../services/publisher_service.dart';
import '../widgets/publisher_delete_dialog.dart';
import 'publisher_add_screen.dart';
import 'publisher_detail_screen.dart';

/// Nguyen Duy Khang - CE192012
/// Màn hình quản lý danh sách nhà xuất bản (PRM-023: Danh sách, PRM-024: Thêm mới, PRM-025: Cập nhật, PRM-026: Xóa)
class PublisherListScreen extends StatefulWidget {
  const PublisherListScreen({super.key});

  @override
  State<PublisherListScreen> createState() => _PublisherListScreenState();
}

/// Nguyen Duy Khang - CE192012
/// State quản lý vòng đời, tìm kiếm và trạng thái hiển thị của danh sách nhà xuất bản
class _PublisherListScreenState extends State<PublisherListScreen> {
  // Service gọi API nhà xuất bản
  final PublisherService service = PublisherService();

  // Biến lưu trữ Future chứa danh sách nhà xuất bản tải từ API
  late Future<List<Publisher>> publishersFuture;

  // Controller và từ khóa phục vụ tìm kiếm nhanh nhà xuất bản
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    // Tự động gọi API lấy danh sách nhà xuất bản khi khởi tạo màn hình (PRM-023)
    publishersFuture = service.getPublishers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  /// PRM-025: Chuyển sang màn hình cập nhật thông tin nhà xuất bản; reload danh sách nếu sửa thành công
  void openEditPublisher(Publisher publisher) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PublisherAddScreen(publisher: publisher),
      ),
    ).then((updated) {
      if (updated == true) {
        // Tải lại danh sách ngay lập tức khi cập nhật thành công
        refreshPublishers();
      }
    });
  }

  /// PRM-026: Hiển thị dialog xác nhận xóa nhỏ gọn và gọi API xóa nhà xuất bản
  Future<void> confirmAndDelete(Publisher publisher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PublisherDeleteDialog(publisher: publisher),
    );

    if (confirmed == true && mounted) {
      try {
        // Gọi API DELETE /api/publishers/{id} để xóa nhà xuất bản (PRM-026)
        await service.deletePublisher(publisher.id);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa nhà xuất bản thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Tải lại danh sách để nhà xuất bản bị xóa biến mất khỏi màn hình ngay lập tức (PRM-026)
        refreshPublishers();
      } catch (error) {
        if (!mounted) return;

        final message = error.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// PRM-023: Chuyển sang màn hình chi tiết nhà xuất bản dựa theo ID được chọn
  void openDetail(String id) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return PublisherDetailScreen(
            publisherId: id,
          );
        },
      ),
    ).then((result) {
      // Tải lại dữ liệu khi quay về để đảm bảo cập nhật nếu có sửa/xóa từ màn hình chi tiết
      refreshPublishers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // KHU VỰC HEADER: TIÊU ĐỀ & CÁC NÚT THAO TÁC TRÊN ĐẦU
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nhà xuất bản',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Quản lý danh sách nhà xuất bản',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Nút Thêm mới (PRM-024)
                    FilledButton.icon(
                      onPressed: openAddPublisher,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Thêm mới',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0878F9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Nút Tải lại danh sách (Refresh)
                    IconButton(
                      onPressed: refreshPublishers,
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
                      tooltip: 'Tải lại',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // THANH TÌM KIẾM NHÀ XUẤT BẢN TIỆN LỢI
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchKeyword = value.trim().toLowerCase();
                      });
                    },
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên, địa chỉ, email, số điện thoại...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                      suffixIcon: _searchKeyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchKeyword = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0878F9), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // KHU VỰC HIỂN THỊ DANH SÁCH (FUTUREBUILDER - PRM-023)
          Expanded(
            child: FutureBuilder<List<Publisher>>(
              future: publishersFuture,
              builder: (context, snapshot) {
                // TRẠNG THÁI 1: ĐANG TẢI DỮ LIỆU
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0878F9)),
                  );
                }

                // TRẠNG THÁI 2: GẶP LỖI KHI GỌI API
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Không thể tải danh sách nhà xuất bản',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            snapshot.error.toString().replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: refreshPublishers,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Thử lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0878F9),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // LẤY DỮ LIỆU DANH SÁCH THỰC TẾ
                final allPublishers = snapshot.data ?? [];

                // Lọc theo từ khóa tìm kiếm
                final filteredPublishers = allPublishers.where((p) {
                  if (_searchKeyword.isEmpty) return true;
                  final name = p.name.toLowerCase();
                  final address = p.address.toLowerCase();
                  final email = p.email.toLowerCase();
                  final phone = p.phone.toLowerCase();
                  return name.contains(_searchKeyword) ||
                      address.contains(_searchKeyword) ||
                      email.contains(_searchKeyword) ||
                      phone.contains(_searchKeyword);
                }).toList();

                // TRẠNG THÁI 3: DANH SÁCH TRỐNG
                if (filteredPublishers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              color: Color(0xFF94A3B8),
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _searchKeyword.isNotEmpty
                                ? 'Không tìm thấy nhà xuất bản phù hợp'
                                : 'Chưa có nhà xuất bản nào',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchKeyword.isNotEmpty
                                ? 'Hãy thử tìm kiếm với từ khóa khác'
                                : 'Nhấn nút "Thêm mới" để tạo nhà xuất bản đầu tiên',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // TRẠNG THÁI 4: HIỂN THỊ DANH SÁCH ĐẸP MẮT, RÕ RÀNG (PRM-023)
                return RefreshIndicator(
                  onRefresh: refreshPublishers,
                  color: const Color(0xFF0878F9),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: filteredPublishers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final publisher = filteredPublishers[index];

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => openDetail(publisher.id),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                // Icon đại diện NXB tròn nền xanh nhạt
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.apartment_rounded,
                                    color: Color(0xFF0878F9),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Thông tin tên và chi tiết
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        publisher.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Địa chỉ
                                      if (publisher.address.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on_outlined,
                                                size: 14,
                                                color: Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  publisher.address,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Số điện thoại & Email
                                      Row(
                                        children: [
                                          if (publisher.phone.isNotEmpty) ...[
                                            const Icon(
                                              Icons.phone_outlined,
                                              size: 13,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              publisher.phone,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          if (publisher.email.isNotEmpty) ...[
                                            const Icon(
                                              Icons.email_outlined,
                                              size: 13,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(width: 3),
                                            Expanded(
                                              child: Text(
                                                publisher.email,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Các nút hành động: Sửa, Xóa và Mũi tên
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Nút Chỉnh sửa (PRM-025)
                                    IconButton(
                                      tooltip: 'Sửa',
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Color(0xFF0878F9),
                                        size: 19,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFFF1F5F9),
                                        padding: const EdgeInsets.all(8),
                                        minimumSize: const Size(36, 36),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => openEditPublisher(publisher),
                                    ),
                                    const SizedBox(width: 6),

                                    // Nút Xóa (PRM-026)
                                    IconButton(
                                      tooltip: 'Xóa',
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 19,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFFFEE2E2),
                                        padding: const EdgeInsets.all(8),
                                        minimumSize: const Size(36, 36),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => confirmAndDelete(publisher),
                                    ),
                                    const SizedBox(width: 6),

                                    // Icon điều hướng xem chi tiết
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFFCBD5E1),
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
