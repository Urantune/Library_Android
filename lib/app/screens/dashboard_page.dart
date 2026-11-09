import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../../core/auth/user_role.dart';
import '../../features/authors/presentation/screens/author_list_screen.dart';
import '../../features/bottom_nav/bottom_nav_bar.dart';
import '../../features/books/presentation/screens/book_list_screen.dart';
import '../../features/categories/screens/category_screen.dart';
import '../../features/loans/presentation/screens/loan_history_screen.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/publishers/screens/publisher_list_screen.dart';
import '../../features/sign/controllers/auth_controller.dart';
import '../../features/users/presentation/screens/profile_screen.dart';
import '../../features/users/presentation/screens/user_list_screen.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/push_menu_layout.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import 'dashboard_home.dart';
import 'library_screen.dart';
import 'my_loans_screen.dart';
import 'placeholder_page.dart';

/// Khung chính (điều hướng) — menu và dashboard thay đổi theo vai trò.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Widget _buildBottomNavPage(int bottomNavIndex, UserRole role) {
    switch (bottomNavIndex) {
      case 1:
        // ADMIN: quản lý người dùng. Thủ thư: quản lý mượn trả.
        // Thành viên: sách đã mượn của tôi.
        if (role.canManageUsers) return const UserListScreen();
        if (role.canManageCatalog) return const LoanHistoryScreen();
        return const MyLoansScreen();
      case 2:
        return const NotificationListScreen();
      case 3:
        return const ProfileScreen();
      case 0:
      default:
        return const DashboardHome();
    }
  }

  Widget _buildPage(NavigationProvider nav, UserRole role) {
    switch (nav.selectedIndex) {
      case NavIndex.dashboard:
        return _buildBottomNavPage(nav.bottomNavIndex, role);
      case NavIndex.book:
        return role.canManageCatalog
            ? const BookListScreen()
            : const LibraryScreen();
      case NavIndex.author:
        return const AuthorListScreen();
      case NavIndex.category:
        return CategoryScreen(onBack: nav.goToDashboard);
      case NavIndex.publisher:
        return const PublisherListScreen();
      case NavIndex.user:
        return role.canManageUsers
            ? const UserListScreen()
            : const MyLoansScreen();
      case NavIndex.loan:
        return role.canManageCatalog
            ? const LoanHistoryScreen()
            : const MyLoansScreen();
      case NavIndex.notification:
        return const NotificationListScreen();
      default:
        return const PlaceholderPage();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = context.watch<NavigationProvider>();
    final role = UserRole.fromRoles(
      ref.watch(authControllerProvider).user?.roles ?? const ['MEMBER'],
    );
    final showBottomNav = nav.showBottomNav;

    return Scaffold(
      // Nền phía sau là màu sidebar → khi nội dung trượt đi sẽ lộ ra liền mạch.
      backgroundColor: AppColors.sidebar,
      body: PushMenuLayout(
        isOpen: nav.isMenuOpen,
        onClose: nav.closeMenu,
        menu: SafeArea(
          child: Sidebar(
            selectedIndex: nav.selectedIndex,
            role: role,
            onSelected: nav.selectMenu, // chọn xong tự đóng menu
            onClose: nav.closeMenu,
          ),
        ),
        child: Column(
          children: [
            const TopBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(
                    showBottomNav
                        ? 'bn${nav.bottomNavIndex}'
                        : 'sb${nav.selectedIndex}',
                  ),
                  child: _buildPage(nav, role),
                ),
              ),
            ),
            // Bottom nav nằm trong nội dung nên cũng trượt theo
            if (showBottomNav)
              BottomNavBar(
                currentIndex: nav.bottomNavIndex,
                role: role,
                onTap: nav.selectBottomNav,
              ),
          ],
        ),
      ),
    );
  }
}
