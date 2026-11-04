import 'dart:convert';
import '../constants/auth_constants.dart';

class Validators {
  Validators._();
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AuthStrings.emailRequired;
    if (text.length > 254 || !_email.hasMatch(text)) {
      return AuthStrings.emailInvalid;
    }
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return AuthStrings.passwordRequired;
    if (utf8.encode(value).length > 72) {
      return 'Mật khẩu không được vượt quá 72 byte.';
    }
    return null;
  }

  static String? password(String? value) {
    final error = loginPassword(value);
    if (error != null) return error;
    return value!.length < 8 ? 'Mật khẩu cần ít nhất 8 ký tự.' : null;
  }

  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2 ||
        text.length > 100 ||
        text.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
      return 'Họ tên cần 2–100 ký tự hợp lệ.';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(
          String Function() original) =>
      (value) => value == original() && (value?.isNotEmpty ?? false)
          ? null
          : AuthStrings.confirmNotMatch;
}
