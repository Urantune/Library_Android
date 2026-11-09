import 'package:flutter/material.dart';

import '../services/menu_service.dart';
import '../theme/app_colors.dart';
import 'sidebar_tile.dart';
import '../models/menu_item.dart';
import 'logout_dialog.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onClose;

  /// true: ADMIN/LIBRARIAN (thấy đầy đủ menu quản trị).
  /// false: độc giả (chỉ thấy các mục dành cho bạn đọc).
  final bool isStaff;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.onClose,
    this.isStaff = true,
  });

  /// Vị trí các mục chỉ dành cho quản trị/thủ thư trong MenuService.mainItems:
  /// Tác giả (2), Thể loại (3), Nhà xuất bản (4), Người dùng (5).
  static const _staffOnlyMain = {2, 3, 4, 5};

  /// Đổi nhãn thân thiện với độc giả, giữ nguyên index điều hướng.
  MenuItem _memberItem(int index, MenuItem item) => switch (index) {
        0 => const MenuItem(Icons.home_rounded, 'Trang chủ'),
        1 => const MenuItem(Icons.local_library_outlined, 'Thư viện'),
        6 => const MenuItem(Icons.history_rounded, 'Sách đã mượn'),
        _ => item,
      };

  @override
  Widget build(BuildContext context) {
    const mainItems = MenuService.mainItems;
    const bottomItems = MenuService.bottomItems;

    return Container(
      color: AppColors.sidebar,
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 12),
              child: Row(
                children: [
                  const Icon(Icons.local_library_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Thư viện số',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng menu',
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < mainItems.length; i++)
                    if (isStaff || !_staffOnlyMain.contains(i))
                      SidebarTile(
                        item: isStaff
                            ? mainItems[i]
                            : _memberItem(i, mainItems[i]),
                        selected: selectedIndex == i,
                        onTap: () => onSelected(i),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.white.withOpacity(0.12), height: 1),
          ),
          const SizedBox(height: 12),
          // Báo cáo / Quản trị hệ thống chỉ dành cho quản trị, thủ thư.
          if (isStaff)
            for (int i = 0; i < bottomItems.length; i++)
              SidebarTile(
                item: bottomItems[i],
                selected: selectedIndex == mainItems.length + i,
                onTap: () => onSelected(mainItems.length + i),
              ),

          
          SidebarTile(
            item: const MenuItem(Icons.logout_rounded, 'Đăng xuất'),
            selected:
                false,
            onTap: () => confirmLogout(context),
          ),
        ],
      ),
    );
  }
}
