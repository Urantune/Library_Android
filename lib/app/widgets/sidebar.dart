import 'package:flutter/material.dart';

import '../services/menu_service.dart';
import '../theme/app_colors.dart';
import 'sidebar_tile.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onClose;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.onClose,
  });

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
                    SidebarTile(
                      item: mainItems[i],
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
          for (int i = 0; i < bottomItems.length; i++)
            SidebarTile(
              item: bottomItems[i],
              selected: selectedIndex == mainItems.length + i,
              onTap: () => onSelected(mainItems.length + i),
            ),
        ],
      ),
    );
  }
}