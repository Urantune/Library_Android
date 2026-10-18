import 'package:flutter/material.dart';

class AuthColors {
  AuthColors._();

  static const Color primary = Color(0xFF1565F0);
  static const Color pageBackground = Color(0xFFF1F5FB);
  static const Color cardBackground = Colors.white;
  static const Color sidePanelBottom = Color(0xFFFBEBDD);
  static const Color textPrimary = Color(0xFF1B2333);
  static const Color textSecondary = Color(0xFF7C8AA5);
  static const Color border = Color(0xFFE3E8F1);
  static const Color error = Color(0xFFD93025);
}

class AuthStrings {
  AuthStrings._();

  // Chung
  static const String email = 'Email';
  static const String emailHint = 'Nhập email';
  static const String password = 'Mật khẩu';
  static const String passwordHint = 'Nhập mật khẩu';

  // Panel bên trái
  static const String sideTitle = 'Thư viện số';
  static const String sideSlogan = 'Kiến thức mở - Tương lai rộng';
  static const String sideDescription =
      'Tìm kiếm, mượn và quản lý sách dễ dàng hơn';

  // Đăng nhập
  static const String loginTitle = 'Đăng nhập';
  static const String loginSubtitle = 'Chào mừng bạn trở lại';
  static const String rememberMe = 'Ghi nhớ đăng nhập';
  static const String forgotPassword = 'Quên mật khẩu?';
  static const String noAccount = 'Chưa có tài khoản? ';
  static const String goToRegister = 'Đăng ký';
  static const String loginSuccess = 'Đăng nhập thành công';

  // Đăng ký
  static const String registerTitle = 'Đăng ký';
  static const String registerSubtitle = 'Tạo tài khoản để bắt đầu mượn sách';
  static const String fullName = 'Họ và tên';
  static const String fullNameHint = 'Nhập họ và tên';
  static const String confirmPassword = 'Xác nhận mật khẩu';
  static const String confirmPasswordHint = 'Nhập lại mật khẩu';
  static const String agreeTerms = 'Tôi đồng ý với điều khoản sử dụng';
  static const String haveAccount = 'Đã có tài khoản? ';
  static const String goToLogin = 'Đăng nhập';
  static const String registerSuccess =
      'Đăng ký thành công. Hãy đăng nhập để tiếp tục';

  // Lỗi
  static const String emailRequired = 'Vui lòng nhập email';
  static const String emailInvalid = 'Email không hợp lệ';
  static const String passwordRequired = 'Vui lòng nhập mật khẩu';
  static const String passwordTooShort = 'Mật khẩu cần ít nhất 6 ký tự';
  static const String nameRequired = 'Vui lòng nhập họ và tên';
  static const String confirmRequired = 'Vui lòng nhập lại mật khẩu';
  static const String confirmNotMatch = 'Mật khẩu xác nhận không khớp';
  static const String mustAgreeTerms =
      'Bạn cần đồng ý với điều khoản để đăng ký';
  static const String wrongCredentials = 'Email hoặc mật khẩu không đúng';
  static const String emailExists = 'Email này đã được đăng ký';
  static const String unknownError = 'Đã có lỗi xảy ra, vui lòng thử lại';
}
