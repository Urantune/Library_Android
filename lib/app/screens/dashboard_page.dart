import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/authors/presentation/screens/author_list_screen.dart';
import '../../features/bottom_nav/bottom_nav_bar.dart';
import '../../features/books/presentation/screens/book_list_screen.dart';
import '../../features/categories/screens/category_screen.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/publishers/screens/publisher_list_screen.dart';
import '../../features/users/presentation/screens/profile_screen.dart';
import '../../features/users/presentation/screens/user_list_screen.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/top_bar.dart';
import 'dashboard_home.dart';
import 'placeholder_page.dart';

/// Khung chính (điều hướng).
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Widget _buildBottomNavPage(int bottomNavIndex) {
    switch (bottomNavIndex) {
      case 1:
        return const UserListScreen();
      case 2:
        return const NotificationListScreen();
      case 3:
        return const ProfileScreen();
      case 0:
      default:
        return const DashboardHome();
    }
  }

  Widget _buildPage(NavigationProvider nav) {
    switch (nav.selectedIndex) {
      case NavIndex.dashboard:
        return _buildBottomNavPage(nav.bottomNavIndex);
      case NavIndex.book:
        return const BookListScreen();
      case NavIndex.author:
        return const AuthorListScreen();
      case NavIndex.category:
        return CategoryScreen(onBack: nav.goToDashboard);
      case NavIndex.publisher:
        return const PublisherListScreen();
      case NavIndex.user:
        return const UserListScreen();
      case NavIndex.notification:
        return const NotificationListScreen();
      default:
        return const PlaceholderPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final showBottomNav = nav.showBottomNav;

    return Scaffold(
      // Menu trượt từ trái sang khi bấm nút 3 gạch (hoặc vuốt từ mép trái).
      drawer: const AppDrawer(),
      body: Column(
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
                child: _buildPage(nav),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: showBottomNav
          ? BottomNavBar(
              currentIndex: nav.bottomNavIndex,
              onTap: nav.selectBottomNav,
            )
          : null,
    );
  }
}
