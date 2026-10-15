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

  int _bottomNavIndex = 0;

  int get selectedIndex => _selectedIndex;
  int get bottomNavIndex => _bottomNavIndex;

  bool get showBottomNav => _selectedIndex == NavIndex.dashboard;

  void selectMenu(int index) {
    _selectedIndex = index;
    if (index == NavIndex.dashboard) _bottomNavIndex = 0;
    notifyListeners();
  }

  void selectBottomNav(int index) {
    _bottomNavIndex = index;
    notifyListeners();
  }

  void goToDashboard() => selectMenu(NavIndex.dashboard);
}
