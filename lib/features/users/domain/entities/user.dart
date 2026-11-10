class User {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['full_name'] ?? '').toString(),
      phone: json['phone']?.toString(),
      role: _normalizeRole(
        (json['role'] ?? _firstRole(json['roles']) ?? 'MEMBER').toString(),
      ),
      status: (json['status'] ?? 'ACTIVE').toString(),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? username,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    String? status,
  }) =>
      User(
        id: id,
        username: username ?? this.username,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  /// DB chỉ dùng 2 vai trò: MEMBER (Độc giả) và ADMIN (Quản trị viên).
  /// Vẫn nhận mã cũ (USER/STAFF/LIBRARIAN) để không vỡ dữ liệu cũ.
  static String _normalizeRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'ADMIN';
      case 'MEMBER':
      case 'USER':
      case 'STAFF':
      case 'LIBRARIAN':
      default:
        return 'MEMBER';
    }
  }

  static String? _firstRole(dynamic roles) =>
      roles is List && roles.isNotEmpty ? roles.first.toString() : null;
}
