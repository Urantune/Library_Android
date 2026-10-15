import 'package:flutter/material.dart';

import '../models/menu_item.dart';

class MenuService {
  static const mainItems = [
    MenuItem(Icons.home_rounded, 'Dashboard'),
    MenuItem(Icons.menu_book_rounded, 'Sách'),
    MenuItem(Icons.person_outline_rounded, 'Tác giả'),
    MenuItem(Icons.category_outlined, 'Thể loại'),
    MenuItem(Icons.apartment_rounded, 'Nhà xuất bản'),
    MenuItem(Icons.people_outline_rounded, 'Người dùng'),
    MenuItem(Icons.swap_horiz_rounded, 'Mượn - Trả'),
    MenuItem(Icons.bookmark_border_rounded, 'Đặt trước'),
    MenuItem(Icons.notifications_none_rounded, 'Thông báo'),
  ];

  static const bottomItems = [
    MenuItem(Icons.bar_chart_rounded, 'Báo cáo'),
    MenuItem(Icons.settings_outlined, 'Quản trị hệ thống'),
  ];
}
