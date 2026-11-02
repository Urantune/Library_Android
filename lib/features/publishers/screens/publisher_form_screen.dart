import 'package:flutter/material.dart';

// Import Model Publisher để tương thích với màn hình Detail.
import '../models/publisher.dart';

// Import Service để gọi API Create.
import '../services/publisher_service.dart';

// ============================================================
// PUBLISHER FORM SCREEN - PRM-024
//
// Chức năng:
// 1. Hiển thị form thêm nhà xuất bản.
// 2. Nhận dữ liệu người dùng nhập.
// 3. Kiểm tra dữ liệu bằng Form Validation.
// 4. Gọi PublisherService để tạo nhà xuất bản.
// 5. Trả kết quả về màn hình List.
// ============================================================

class PublisherFormScreen extends StatefulWidget {
  // publisher = null: Chế độ thêm mới.
  // publisher != null: Được mở từ màn hình Detail.
  //
  // Giữ constructor này để tương thích với code PRM-023.
  final Publisher? publisher;

  const PublisherFormScreen({
    super.key,
    this.publisher,
  });

  @override
  State<PublisherFormScreen> createState() => _PublisherFormScreenState();
}

class _PublisherFormScreenState extends State<PublisherFormScreen> {
  // ==========================================================
  // 1. FORM KEY
  // ==========================================================

  // Dùng để quản lý Form và gọi validate().
  final _formKey = GlobalKey<FormState>();

  // ==========================================================
  // 2. TEXT EDITING CONTROLLERS
  // ==========================================================

  // Lấy dữ liệu người dùng nhập vào từng trường.

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _addressController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  // ==========================================================
  // 3. PUBLISHER SERVICE
  // ==========================================================

  // Sử dụng Service để giao tiếp với Backend.
  final PublisherService _publisherService = PublisherService();

  // ==========================================================
  // 4. SUBMIT STATE
  // ==========================================================

  // true: Đang gửi dữ liệu.
  // false: Đang ở trạng thái bình thường.
  bool _isSubmitting = false;

  // ==========================================================
  // 5. INIT STATE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    // Nếu được mở từ Detail thì điền dữ liệu Publisher hiện tại.
    // Phần Update sẽ được triển khai ở PRM-025.

    final publisher = widget.publisher;

    if (publisher != null) {
      _nameController.text = publisher.name;
      _addressController.text = publisher.address;
      _emailController.text = publisher.email;
      _phoneController.text = publisher.phone;
    }
  }

  // ==========================================================
  // 6. DISPOSE
  // ==========================================================

  @override
  void dispose() {
    // Giải phóng các Controller khi rời khỏi màn hình.
    // Tránh giữ tài nguyên không cần thiết.

    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  // ==========================================================
  // 7. VALIDATE NAME
  // ==========================================================

  // Tên nhà xuất bản là trường bắt buộc.

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên nhà xuất bản';
    }

    if (value.trim().length < 2) {
      return 'Tên phải có ít nhất 2 ký tự';
    }

    if (value.trim().length > 100) {
      return 'Tên không được vượt quá 100 ký tự';
    }

    return null;
  }

  // ==========================================================
  // 8. VALIDATE EMAIL
  // ==========================================================

  // Email không bắt buộc.
  // Nếu nhập thì phải đúng định dạng.

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final emailRegex = RegExp(
      r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không đúng định dạng';
    }

    return null;
  }

  // ==========================================================
  // 9. VALIDATE PHONE
  // ==========================================================

  // Số điện thoại không bắt buộc.
  // Nếu nhập thì chỉ cho phép định dạng số điện thoại hợp lệ.

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final phoneRegex = RegExp(
      r'^\+?[0-9\s().-]{8,20}$',
    );

    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Số điện thoại không hợp lệ';
    }

    return null;
  }

  // ==========================================================
  // 10. CREATE PUBLISHER
  // ==========================================================

  Future<void> _submitForm() async {
    // PRM-024 chỉ thực hiện chức năng Create.
    // Nếu có Publisher thì đây là chế độ Edit,
    // sẽ được xử lý ở PRM-025.

    if (widget.publisher != null) {
      return;
    }

    // BƯỚC 1: Kiểm tra toàn bộ dữ liệu trong Form.
    //
    // Nếu có trường không hợp lệ thì dừng.
    // Flutter sẽ tự hiển thị thông báo validation.

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // BƯỚC 2: Ẩn bàn phím sau khi người dùng nhấn Submit.

    FocusScope.of(context).unfocus();

    // BƯỚC 3: Chuyển trạng thái sang đang gửi dữ liệu.

    setState(() {
      _isSubmitting = true;
    });

    try {
      // BƯỚC 4: Gọi PublisherService để tạo Publisher.
      //
      // Lấy dữ liệu từ các TextEditingController.
      // trim() loại bỏ khoảng trắng đầu và cuối.

      await _publisherService.createPublisher(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      // Kiểm tra màn hình còn tồn tại hay không.
      if (!mounted) return;

      // BƯỚC 5: Tạo thành công.
      //
      // Navigator.pop(context, true):
      // Đóng Form và gửi kết quả true về màn hình List.
      // List sẽ nhận true để tải lại dữ liệu.

      Navigator.pop(context, true);
    } catch (error) {
      // BƯỚC 6: Nếu API thất bại thì hiển thị lỗi.

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getErrorMessage(error),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================================
  // 11. ERROR MESSAGE
  // ==========================================================

  // Chuyển lỗi thành thông báo dễ hiểu cho người dùng.

  String _getErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  // ==========================================================
  // 12. COMMON TEXT FIELD
  // ==========================================================

  // Tạo một Widget TextFormField dùng chung.
  // Giúp tránh viết lại giao diện cho từng trường.

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        // Controller quản lý dữ liệu nhập.
        controller: controller,

        // Hàm kiểm tra dữ liệu.
        validator: validator,

        // Kiểu bàn phím.
        keyboardType: keyboardType,

        // Giới hạn độ dài nếu có.
        maxLength: maxLength,

        // Không cho nhập khi đang Submit.
        enabled: !_isSubmitting && widget.publisher == null,

        decoration: InputDecoration(
          labelText: label,
          hintText: hint,

          prefixIcon: Icon(icon),

          filled: true,
          fillColor: const Color(0xFFF8FAFC),

          // Viền mặc định.
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          // Viền khi chưa Focus.
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),

          // Viền khi Focus.
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF2563EB),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 13. BUILD UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // Xác định Form đang ở chế độ nào.
    final bool isEditMode = widget.publisher != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      // ================= APP BAR =================

      appBar: AppBar(
        title: Text(
          isEditMode ? 'Chỉnh sửa nhà xuất bản' : 'Thêm nhà xuất bản',
        ),
      ),

      // ================= BODY =================

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          // Giới hạn chiều rộng để giao diện đẹp trên Tablet/Web.
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650,
            ),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= HEADER =================

                      const Center(
                        child: Icon(
                          Icons.apartment_rounded,
                          size: 60,
                          color: Color(0xFF2563EB),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: Text(
                          isEditMode
                              ? 'Thông tin nhà xuất bản'
                              : 'Thông tin nhà xuất bản mới',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Center(
                        child: Text(
                          'Vui lòng điền thông tin bên dưới',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ================= NAME =================

                      _buildTextField(
                        label: 'Tên nhà xuất bản *',
                        hint: 'Ví dụ: Nhà xuất bản Kim Đồng',
                        icon: Icons.business,
                        controller: _nameController,
                        validator: _validateName,
                        maxLength: 100,
                      ),

                      // ================= ADDRESS =================

                      _buildTextField(
                        label: 'Địa chỉ',
                        hint: 'Nhập địa chỉ nhà xuất bản',
                        icon: Icons.location_on_outlined,
                        controller: _addressController,
                        maxLength: 255,
                      ),

                      // ================= EMAIL =================

                      _buildTextField(
                        label: 'Email',
                        hint: 'publisher@example.com',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        maxLength: 100,
                      ),

                      // ================= PHONE =================

                      _buildTextField(
                        label: 'Số điện thoại',
                        hint: 'Nhập số điện thoại',
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                        maxLength: 20,
                      ),

                      const SizedBox(height: 10),

                      // ================= EDIT NOTICE =================

                      if (isEditMode)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Chức năng chỉnh sửa sẽ được '
                            'triển khai trong PRM-025.',
                            style: TextStyle(
                              color: Colors.orange,
                            ),
                          ),
                        ),

                      // ================= BUTTONS =================

                      Row(
                        children: [
                          // Nút Hủy.
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Hủy'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Nút thêm nhà xuất bản.
                          Expanded(
                            child: ElevatedButton(
                              // Không cho Submit nhiều lần.
                              // Nếu đang Edit thì chờ PRM-025.
                              onPressed: _isSubmitting || isEditMode
                                  ? null
                                  : _submitForm,

                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),

                              // Hiện loading khi đang gửi API.
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Thêm nhà xuất bản',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
