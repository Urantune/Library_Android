import '../constants/auth_constants.dart';

/// Các hàm kiểm tra dữ liệu nhập. Trả về null nếu hợp lệ,
/// ngược lại trả về thông báo lỗi.
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w.+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$');

  static const int minPasswordLength = 6;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return AuthStrings.emailRequired;
    if (!_emailRegex.hasMatch(v)) return AuthStrings.emailInvalid;
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return AuthStrings.passwordRequired;
    if (v.length < minPasswordLength) return AuthStrings.passwordTooShort;
    return null;
  }

  static String? fullName(String? value) {
    if ((value ?? '').trim().isEmpty) return AuthStrings.nameRequired;
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if ((value ?? '').isEmpty) return AuthStrings.confirmRequired;
      if (value != original()) return AuthStrings.confirmNotMatch;
      return null;
    };
  }
}
