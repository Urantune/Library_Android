import 'package:flutter/material.dart';

import '../../core/auth/user_role.dart';
import '../providers/navigation_provider.dart';
import '../services/menu_service.dart';
import '../theme/app_colors.dart';
import 'sidebar_tile.dart';
import '../models/menu_item.dart';
import 'logout_dialog.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final UserRole role;
  final ValueChanged<int> onSelected;
  final VoidCallback onClose;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.role,
    required this.onSelected,
    required this.onClose,
  });

  /// Ẩn các mục không đúng quyền của role hiện tại.
  /// Vẫn truyền đúng index gốc để không lệch điều hướng.
  bool _showMainItem(int index) {
    switch (index) {
      case 2: // Tác giả
      case 3: // Thể loại
      case 4: // Nhà xuất bản
        return role.canManageCatalog;
      case 5: // Người dùng
        return role.canManageUsers;
      default:
        return true;
    }
  }

  /// Đổi nhãn thân thiện với bạn đọc, giữ nguyên index điều hướng.
  MenuItem _displayItem(int index, MenuItem item) {
    if (role.canManageCatalog) return item;
    if (index == NavIndex.book) return MenuItem(item.icon, 'Thư viện');
    if (index == NavIndex.loan) return MenuItem(item.icon, 'Sách đã mượn');
    return item;
  }

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
          // Header: logo + nút 3 gạch (đóng menu)
          SizedBox(
            height: 72, // bằng chiều cao TopBar
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
                    if (_showMainItem(i))
                      SidebarTile(
                        item: _displayItem(i, mainItems[i]),
                        selected: selectedIndex == i,
                        onTap: () => onSelected(i),
                      ),
                ],
              ),
            ),
          ),
          if (role.canViewReports) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.white.withOpacity(0.12), height: 1),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < bottomItems.length; i++)
              SidebarTile(
                item: bottomItems[i],
                selected: selectedIndex == mainItems.length + i,
                onTap: () => onSelected(mainItems.length + i),
              ),
          ],
          // Nút đăng xuất
          SidebarTile(
            item: const MenuItem(Icons.logout_rounded, 'Đăng xuất'),
            selected:
                false, // không phải một trang nên không bao giờ "đang chọn"
            onTap: () => confirmLogout(context),
          ),
        ],
      ),
    );
  }
}
