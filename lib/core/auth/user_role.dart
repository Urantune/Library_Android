/// Vai trò người dùng, chuẩn hoá từ danh sách role backend trả về
/// (ADMIN / LIBRARIAN / MEMBER, có thể gặp STAFF / USER ở dữ liệu cũ).
enum UserRole {
  admin('Quản trị viên'),
  librarian('Thủ thư'),
  member('Thành viên');

  const UserRole(this.label);

  final String label;

  static UserRole fromRoles(Iterable<String> roles) {
    final normalized = roles.map((role) => role.trim().toUpperCase()).toSet();
    if (normalized.contains('ADMIN')) return UserRole.admin;
    if (normalized.contains('LIBRARIAN') || normalized.contains('STAFF')) {
      return UserRole.librarian;
    }
    return UserRole.member;
  }

  static UserRole fromRole(String? role) => fromRoles([role ?? 'MEMBER']);

  bool get isAdmin => this == UserRole.admin;

  /// Chỉ ADMIN được quản lý tài khoản người dùng.
  bool get canManageUsers => this == UserRole.admin;

  /// ADMIN + thủ thư được quản lý danh mục sách.
  bool get canManageCatalog => this != UserRole.member;

  /// Chỉ ADMIN xem được báo cáo / quản trị hệ thống.
  bool get canViewReports => this == UserRole.admin;
}
