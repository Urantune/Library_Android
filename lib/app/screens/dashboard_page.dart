import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' show WatchContext;

import '../../features/authors/presentation/screens/author_list_screen.dart';
import '../../features/bottom_nav/bottom_nav_bar.dart';
import '../../features/books/presentation/screens/book_list_screen.dart';
import '../../features/categories/screens/category_screen.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/loans/presentation/screens/borrowed_loans_screen.dart';
import '../../features/publishers/screens/publisher_list_screen.dart';
import '../../features/reservations/screens/reservation_list_screen.dart';
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
import 'placeholder_page.dart';
import 'user_dashboard_home.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  /// Chỉ ADMIN dùng dashboard quản trị; còn lại là độc giả (MEMBER).
  bool _isStaff(WidgetRef ref) {
    final roles = ref.watch(
      authControllerProvider.select((state) => state.user?.roles ?? const []),
    );
    return roles.any((role) => role.toUpperCase() == 'ADMIN');
  }

  Widget _buildBottomNavPage(int bottomNavIndex, bool isStaff) {
    final pages = isStaff
        ? const <Widget>[
            DashboardHome(),
            UserListScreen(),
            NotificationListScreen(),
            ProfileScreen(),
          ]
        : const <Widget>[
            UserDashboardHome(),
            BorrowedLoansScreen(),
            NotificationListScreen(),
            ProfileScreen(),
          ];
    final index = bottomNavIndex >= 0 && bottomNavIndex < pages.length
        ? bottomNavIndex
        : 0;
    return pages[index];
  }

  Widget _buildPage(NavigationProvider nav, bool isStaff) {
    switch (nav.selectedIndex) {
      case NavIndex.dashboard:
        return _buildBottomNavPage(nav.bottomNavIndex, isStaff);
      case NavIndex.book:
        // Quản trị/thủ thư quản lý sách; độc giả chỉ xem thư viện (read-only).
        return isStaff ? const BookListScreen() : const LibraryScreen();
      case NavIndex.author:
        return isStaff ? const AuthorListScreen() : const LibraryScreen();
      case NavIndex.category:
        return isStaff
            ? CategoryScreen(onBack: nav.goToDashboard)
            : const LibraryScreen();
      case NavIndex.publisher:
        return isStaff ? const PublisherListScreen() : const LibraryScreen();
      case NavIndex.user:
        // Độc giả không có quyền quản lý người dùng.
        return isStaff ? const UserListScreen() : const ProfileScreen();
      case NavIndex.loan:
        return const BorrowedLoansScreen();
      case NavIndex.reservation:
        return const ReservationListScreen();
      case NavIndex.notification:
        return const NotificationListScreen();
      default:
        return const PlaceholderPage();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = context.watch<NavigationProvider>();
    final showBottomNav = nav.showBottomNav;
    final isStaff = _isStaff(ref);

    return Scaffold(
      backgroundColor: AppColors.sidebar,
      body: PushMenuLayout(
        isOpen: nav.isMenuOpen,
        onClose: nav.closeMenu,
        menu: SafeArea(
          child: Sidebar(
            selectedIndex: nav.selectedIndex,
            onSelected: nav.selectMenu,
            onClose: nav.closeMenu,
            isStaff: isStaff,
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
                  child: _buildPage(nav, isStaff),
                ),
              ),
            ),
            if (showBottomNav)
              BottomNavBar(
                currentIndex: nav.bottomNavIndex,
                isStaff: isStaff,
                onTap: nav.selectBottomNav,
              ),
          ],
        ),
      ),
    );
  }
}
