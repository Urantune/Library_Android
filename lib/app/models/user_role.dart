String roleLabel(String? role) {
  final value = (role ?? '').trim();
  switch (value.toUpperCase()) {
    case 'ADMIN':
      return 'Quản trị viên';
    case 'LIBRARIAN':
      return 'Thủ thư';
    case 'USER':
    case '':
      return 'Độc giả';
    default:
      return value;
  }
}
