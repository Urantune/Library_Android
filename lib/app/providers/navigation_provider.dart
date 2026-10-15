import 'package:flutter/foundation.dart';

/// Vị trí các mục trong menu bên trái.
class NavIndex {
  static const dashboard = 0;
  static const book = 1;
  static const author = 2;
  static const category = 3;
  static const publisher = 4;
  static const user = 5;
  static const notification = 8;
}

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = NavIndex.dashboard;

  // Bottom nav: 0=Trang chủ, 1=Người dùng, 2=Thông báo, 3=Hồ sơ
  int _bottomNavIndex = 0;

  bool _isMenuOpen = false;

  int get selectedIndex => _selectedIndex;
  int get bottomNavIndex => _bottomNavIndex;
  bool get isMenuOpen => _isMenuOpen;

  /// Bottom nav chỉ hiện khi đang ở Dashboard.
  bool get showBottomNav => _selectedIndex == NavIndex.dashboard;

  // ── Menu bên trái ──
  void toggleMenu() {
    _isMenuOpen = !_isMenuOpen;
    notifyListeners();
  }

  void closeMenu() {
    if (!_isMenuOpen) return;
    _isMenuOpen = false;
    notifyListeners();
  }

  // ── Điều hướng ──
  /// Chọn một mục trong menu → đổi trang và tự đóng menu.
  void selectMenu(int index) {
    _selectedIndex = index;
    if (index == NavIndex.dashboard) _bottomNavIndex = 0;
    _isMenuOpen = false;
    notifyListeners();
  }

  void selectBottomNav(int index) {
    _bottomNavIndex = index;
    notifyListeners();
  }

  void goToDashboard() => selectMenu(NavIndex.dashboard);
}
