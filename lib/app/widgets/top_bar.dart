import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/users/presentation/screens/profile_screen.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_colors.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    // Thanh tìm kiếm toàn cục chỉ hiện trên trang chủ (dashboard + bottom nav index 0).
    // Các tab khác đã có thanh tìm kiếm riêng theo chức năng.
    final showSearch =
        nav.selectedIndex == NavIndex.dashboard && nav.bottomNavIndex == 0;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          // Nút 3 gạch — ẩn đi khi menu mở (lúc đó nút nằm trong sidebar)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: context
                    .select<NavigationProvider, bool>((nav) => nav.isMenuOpen)
                ? 0
                : 1,
            child: IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded, color: AppColors.textDark),
              onPressed: () => context.read<NavigationProvider>().toggleMenu(),
            ),
          ),
          const SizedBox(width: 8),
          // Ô tìm kiếm — chỉ hiện trên trang chủ.
          if (showSearch)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm sách, tác giả, thể loại...',
                      hintStyle: const TextStyle(
                          color: AppColors.textGrey, fontSize: 13),
                      prefixIcon: const Icon(Icons.search,
                          size: 20, color: AppColors.textGrey),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          if (showSearch) const SizedBox(width: 16),
          // Thông tin người dùng — bấm để mở hồ sơ cá nhân
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFDCE6FA),
              child: Icon(Icons.person, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nguyễn Văn A',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark),
                ),
                Text(
                  'Thủ thư',
                  style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Chuông thông báo — bấm để mở danh sách thông báo
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationListScreen()),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}