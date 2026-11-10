/// Nguyen Duy Khang - CE192012
/// Model thực thể đại diện cho dữ liệu nhà xuất bản (PRM-023: Danh sách/Chi tiết, PRM-024: Thêm mới, PRM-025: Cập nhật, PRM-026: Xóa)
class Publisher {
  final String id; // Mã định danh nhà xuất bản (UUID)
  final String name; // Tên nhà xuất bản
  final String address; // Địa chỉ
  final String phone; // Số điện thoại
  final String email; // Email liên hệ
  final String website; // Địa chỉ website
  final String status; // Trạng thái hoạt động (ACTIVE/INACTIVE)

  const Publisher({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.website = '',
    this.status = '',
  });

  /// Chuyển đổi dữ liệu JSON nhận từ Backend thành đối tượng Publisher
  factory Publisher.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId == null || rawId.toString().trim().isEmpty) {
      throw const FormatException(
        'Dữ liệu nhà xuất bản không có ID hợp lệ.',
      );
    }

    return Publisher(
      id: rawId.toString(),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  /// Chuyển đối tượng thành JSON để gửi lên Backend khi tạo/sửa (loại bỏ trường rỗng)
  Map<String, dynamic> toWriteJson() {
    return {
      'name': name.trim(),
      if (address.trim().isNotEmpty) 'address': address.trim(),
      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (email.trim().isNotEmpty) 'email': email.trim(),
      if (website.trim().isNotEmpty) 'website': website.trim(),
      'status': status.trim().isEmpty ? 'ACTIVE' : status.trim(),
    };
  }

  /// Tạo bản sao của Publisher với các thuộc tính được cập nhật mới (hỗ trợ PRM-025)
  Publisher copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? status,
  }) {
    return Publisher(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      status: status ?? this.status,
    );
  }
}
