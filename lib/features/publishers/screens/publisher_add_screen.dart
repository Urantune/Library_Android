import 'package:flutter/material.dart';

import '../models/publisher.dart';
import '../services/publisher_service.dart';

/// Nguyen Duy Khang - CE192012
/// Màn hình biểu mẫu thêm mới nhà xuất bản (PRM-024: Create publisher)
class PublisherAddScreen extends StatefulWidget {
  final Publisher? publisher; // Đối tượng nhà xuất bản (nếu null là Thêm mới, nếu có là Chỉnh sửa)

  const PublisherAddScreen({super.key, this.publisher});

  @override
  State<PublisherAddScreen> createState() => _PublisherAddScreenState();
}

/// Nguyen Duy Khang - CE192012
/// State quản lý form nhập liệu, kiểm tra hợp lệ (validation) và gọi API tạo nhà xuất bản
class _PublisherAddScreenState extends State<PublisherAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final PublisherService _service = PublisherService();

  // Các Controller quản lý giá trị nhập liệu của các trường
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _websiteController;

  // Cờ theo dõi trạng thái đang gửi request API lên Backend
  bool _isSaving = false;

  bool get isEditing => widget.publisher != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.publisher?.name ?? '');
    _emailController = TextEditingController(text: widget.publisher?.email ?? '');
    _phoneController = TextEditingController(text: widget.publisher?.phone ?? '');
    _addressController =
        TextEditingController(text: widget.publisher?.address ?? '');
    _websiteController =
        TextEditingController(text: widget.publisher?.website ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  /// PRM-024: Xử lý submit form, validate dữ liệu và gọi API tạo nhà xuất bản mới
  Future<void> _submit() async {
    // 1. Kiểm tra tính hợp lệ của tất cả các trường trong form
    if (!_formKey.currentState!.validate()) return;

    // 2. Bật cờ loading để khóa nút bấm, tránh gửi request trùng lặp
    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        // Cập nhật nhà xuất bản nếu ở chế độ sửa
        await _service.updatePublisher(
          widget.publisher!.id,
          {
            'name': _nameController.text.trim(),
            if (_addressController.text.trim().isNotEmpty)
              'address': _addressController.text.trim(),
            if (_phoneController.text.trim().isNotEmpty)
              'phone': _phoneController.text.trim(),
            if (_emailController.text.trim().isNotEmpty)
              'email': _emailController.text.trim(),
            if (_websiteController.text.trim().isNotEmpty)
              'website': _websiteController.text.trim(),
          },
        );
      } else {
        // Gọi API POST /api/publishers để tạo mới nhà xuất bản (PRM-024)
        await _service.createPublisherData(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          website: _websiteController.text.trim(),
        );
      }

      if (!mounted) return;

      // 3. Hiển thị thông báo thành công dạng SnackBar xanh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Cập nhật nhà xuất bản thành công!'
                : 'Thêm nhà xuất bản thành công!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // 4. Đóng màn hình và trả về true để màn hình danh sách tự động reload
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      // Hiển thị thông báo lỗi từ server (ví dụ: trùng tên NXB, mất mạng,...)
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Sửa nhà xuất bản' : 'Thêm nhà xuất bản',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionCard(
                children: [
                  // TRƯỜNG 1: TÊN NHÀ XUẤT BẢN (BẮT BUỘC, MAX 200 KÝ TỰ THEO BACKEND)
                  _buildLabel('Tên nhà xuất bản *'),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      'Nhập tên nhà xuất bản (bắt buộc)',
                      Icons.apartment_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên nhà xuất bản.';
                      }
                      if (value.trim().length > 200) {
                        return 'Tên nhà xuất bản tối đa 200 ký tự.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // TRƯỜNG 2: EMAIL LIÊN HỆ (ĐỊNH DẠNG EMAIL, MAX 254 KÝ TỰ)
                  _buildLabel('Email liên hệ'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      'ví dụ: nxbkimdong@gmail.com',
                      Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final emailRegex =
                            RegExp(r'^[\w\.\-]+@[\w\-]+(\.[\w\-]+)+$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Định dạng email không hợp lệ.';
                        }
                        if (value.trim().length > 254) {
                          return 'Email tối đa 254 ký tự.';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // TRƯỜNG 3: SỐ ĐIỆN THOẠI (BÀN PHÍM PHONE, MAX 50 KÝ TỰ)
                  _buildLabel('Số điện thoại'),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      'ví dụ: 028 3822 5340',
                      Icons.phone_outlined,
                    ),
                    validator: (value) {
                      if (value != null && value.trim().length > 50) {
                        return 'Số điện thoại tối đa 50 ký tự.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // TRƯỜNG 4: WEBSITE (BÀN PHÍM URL, MAX 500 KÝ TỰ)
                  _buildLabel('Website'),
                  TextFormField(
                    controller: _websiteController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      'ví dụ: https://nxbkimdong.com.vn',
                      Icons.language_rounded,
                    ),
                    validator: (value) {
                      if (value != null && value.trim().length > 500) {
                        return 'Website tối đa 500 ký tự.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // TRƯỜNG 5: ĐỊA CHỈ (NHẬP NHIỀU DÒNG, MAX 500 KÝ TỰ)
                  _buildLabel('Địa chỉ'),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    decoration: _inputDecoration(
                      'Nhập địa chỉ trụ sở nhà xuất bản',
                      Icons.location_on_outlined,
                    ),
                    validator: (value) {
                      if (value != null && value.trim().length > 500) {
                        return 'Địa chỉ tối đa 500 ký tự.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // NÚT LƯU THÔNG TIN (PRM-024)
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0878F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving
                        ? 'Đang lưu...'
                        : (isEditing ? 'Cập nhật nhà xuất bản' : 'Lưu nhà xuất bản'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Khung Card nền trắng bọc ngoài các trường nhập liệu
  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// Tiêu đề nhỏ phía trên mỗi trường nhập liệu
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  /// Thiết kế khung viền và giao diện cho các ô nhập liệu TextFormField
  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0878F9), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
