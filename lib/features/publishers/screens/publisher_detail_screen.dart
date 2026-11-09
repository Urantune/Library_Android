import 'package:flutter/material.dart';

import '../models/publisher.dart';
import '../services/publisher_service.dart';
import '../widgets/publisher_delete_dialog.dart';
import 'publisher_add_screen.dart';

/// Nguyen Duy Khang - CE192012
/// Màn hình hiển thị chi tiết thông tin nhà xuất bản (PRM-023: Xem chi tiết), hỗ trợ cập nhật (PRM-025) và xóa (PRM-026)
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
/// State quản lý việc gọi API lấy thông tin chi tiết, xử lý luồng cập nhật và xóa nhà xuất bản
class _PublisherDetailScreenState extends State<PublisherDetailScreen> {
  // Service gọi API nhà xuất bản
  final PublisherService service = PublisherService();

  // Biến lưu Future chứa dữ liệu chi tiết nhà xuất bản tải từ API
  late Future<Publisher> publisherFuture;

  // Biến lưu cache đối tượng nhà xuất bản hiện tại để dùng cho các hành động trên AppBar
  Publisher? _currentPublisher;

  @override
  void initState() {
    super.initState();
    // Gọi API lấy dữ liệu chi tiết nhà xuất bản theo publisherId truyền vào (PRM-023)
    _loadPublisher();
  }

  /// Khởi tạo và nạp dữ liệu chi tiết nhà xuất bản từ API
  void _loadPublisher() {
    publisherFuture = service.getPublisherById(widget.publisherId).then((data) {
      if (mounted) {
        setState(() {
          _currentPublisher = data;
        });
      }
      return data;
    });
  }

  /// Tải lại thông tin chi tiết của nhà xuất bản từ Backend
  void refreshPublisher() {
    setState(() {
      _loadPublisher();
    });
  }

  /// PRM-025: Mở màn hình cập nhật thông tin nhà xuất bản và reload chi tiết khi sửa thành công
  Future<void> openEdit(Publisher publisher) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PublisherAddScreen(publisher: publisher),
      ),
    );

    if (updated == true && mounted) {
      // Làm mới dữ liệu chi tiết sau khi cập nhật thành công (PRM-025)
      refreshPublisher();
    }
  }

  /// PRM-026: Hiển thị dialog xác nhận xóa nhỏ gọn và thực hiện gọi API xóa nhà xuất bản
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

        // Trả về true để màn hình danh sách tự động làm mới và xóa item khỏi danh sách
        Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Chi tiết nhà xuất bản',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          // Nút xóa nhà xuất bản trên thanh AppBar (PRM-026)
          if (_currentPublisher != null)
            IconButton(
              onPressed: () => confirmAndDelete(_currentPublisher!),
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              tooltip: 'Xóa nhà xuất bản',
            ),
          // Nút làm mới dữ liệu chi tiết
          IconButton(
            onPressed: refreshPublisher,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Làm mới',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Publisher>(
        future: publisherFuture,
        builder: (context, snapshot) {
          // TRẠNG THÁI 1: ĐANG TẢI DỮ LIỆU
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0878F9)),
            );
          }

          // TRẠNG THÁI 2: XẢY RA LỖI KHI GỌI API
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
                      'Không thể tải thông tin nhà xuất bản',
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
                    ElevatedButton(
                      onPressed: refreshPublisher,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0878F9),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final publisher = snapshot.data;

          // TRẠNG THÁI 3: KHÔNG TÌM THẤY DỮ LIỆU
          if (publisher == null) {
            return const Center(
              child: Text(
                'Không tìm thấy nhà xuất bản',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            );
          }

          // TRẠNG THÁI 4: HIỂN THỊ CÁC THÔNG TIN CHI TIẾT (PRM-023)
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // THẺ THÔNG TIN CHÍNH
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Biểu tượng đại diện
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            size: 34,
                            color: Color(0xFF0878F9),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Tên nhà xuất bản
                        Text(
                          publisher.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Huy hiệu trạng thái
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Đang hoạt động',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 18),

                        // Các hàng thông tin chi tiết
                        _buildInfoTile(
                          icon: Icons.tag_rounded,
                          title: 'Mã nhà xuất bản (ID)',
                          value: publisher.id,
                          isCode: true,
                        ),
                        _buildInfoTile(
                          icon: Icons.location_on_outlined,
                          title: 'Địa chỉ trụ sở',
                          value: publisher.address,
                        ),
                        _buildInfoTile(
                          icon: Icons.phone_outlined,
                          title: 'Số điện thoại',
                          value: publisher.phone,
                        ),
                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          title: 'Email liên hệ',
                          value: publisher.email,
                        ),
                        _buildInfoTile(
                          icon: Icons.language_rounded,
                          title: 'Website',
                          value: publisher.website,
                        ),
                        const SizedBox(height: 10),

                        // HÀNG NÚT THAO TÁC (CẬP NHẬT - PRM-025 & XÓA - PRM-026)
                        Row(
                          children: [
                            // Nút Xóa (PRM-026)
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: () => confirmAndDelete(publisher),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                  label: const Text(
                                    'Xóa',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Nút Cập nhật thông tin (PRM-025)
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 46,
                                child: FilledButton.icon(
                                  onPressed: () => openEdit(publisher),
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text(
                                    'Cập nhật thông tin',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF0878F9),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Widget hiển thị từng mục thông tin chi tiết đẹp mắt, trực quan
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    bool isCode = false,
  }) {
    final displayValue = value.trim().isEmpty ? 'Chưa cập nhật' : value.trim();
    final isUnset = value.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCode ? FontWeight.w500 : FontWeight.w600,
                    fontFamily: isCode ? 'monospace' : null,
                    color: isUnset ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
