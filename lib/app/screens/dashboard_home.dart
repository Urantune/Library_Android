import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../../core/auth/user_role.dart';
import '../../features/sign/controllers/auth_controller.dart';
import '../../features/users/presentation/screens/profile_screen.dart';
import '../providers/navigation_provider.dart';
import '../services/dashboard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../widgets/popular_books_section.dart';
import '../widgets/stats_row.dart';

/// Nội dung trang Dashboard — thay đổi theo vai trò người đăng nhập.
class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final authUser = ref.watch(authControllerProvider).user;
    final role = UserRole.fromRoles(authUser?.roles ?? const ['MEMBER']);
    final displayName = (authUser?.fullName.trim().isNotEmpty ?? false)
        ? authUser!.fullName.trim()
        : 'bạn';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Xin chào, $displayName 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Hôm nay là ngày ${now.day} tháng ${now.month}, ${now.year}',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                ),
              ),
              _RoleBadge(role: role),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _subtitleFor(role),
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          StatsRow(stats: DashboardService.getStatsFor(role)),
          const SizedBox(height: 24),
          _QuickActions(role: role),
          const SizedBox(height: 24),
          const PopularBooksSection(),
        ],
      ),
    );
  }

  String _subtitleFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Tổng quan toàn hệ thống thư viện.';
      case UserRole.librarian:
        return 'Tổng quan vận hành mượn trả và kho sách.';
      case UserRole.member:
        return 'Hoạt động đọc sách và mượn trả của bạn.';
    }
  }
}

class _QuickActions extends StatelessWidget {
  final UserRole role;

  const _QuickActions({required this.role});

  List<_QuickAction> _actionsFor(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    switch (role) {
      case UserRole.admin:
        return [
          _QuickAction(
            icon: Icons.menu_book_rounded,
            label: 'Quản lý sách',
            color: AppColors.primary,
            onTap: () => nav.selectMenu(NavIndex.book),
          ),
          _QuickAction(
            icon: Icons.people_rounded,
            label: 'Người dùng',
            color: const Color(0xFF06B6D4),
            onTap: () => nav.selectMenu(NavIndex.user),
          ),
          _QuickAction(
            icon: Icons.swap_horiz_rounded,
            label: 'Mượn - Trả',
            color: const Color(0xFFF59E0B),
            onTap: () => nav.selectMenu(NavIndex.loan),
          ),
          _QuickAction(
            icon: Icons.category_rounded,
            label: 'Thể loại',
            color: const Color(0xFF8B5CF6),
            onTap: () => nav.selectMenu(NavIndex.category),
          ),
        ];
      case UserRole.librarian:
        return [
          _QuickAction(
            icon: Icons.menu_book_rounded,
            label: 'Quản lý sách',
            color: AppColors.primary,
            onTap: () => nav.selectMenu(NavIndex.book),
          ),
          _QuickAction(
            icon: Icons.swap_horiz_rounded,
            label: 'Mượn - Trả',
            color: const Color(0xFFF59E0B),
            onTap: () => nav.selectMenu(NavIndex.loan),
          ),
          _QuickAction(
            icon: Icons.person_outline_rounded,
            label: 'Tác giả',
            color: const Color(0xFF06B6D4),
            onTap: () => nav.selectMenu(NavIndex.author),
          ),
          _QuickAction(
            icon: Icons.bookmark_rounded,
            label: 'Đặt trước',
            color: const Color(0xFFEF4444),
            onTap: () => nav.selectMenu(NavIndex.reservation),
          ),
        ];
      case UserRole.member:
        return [
          _QuickAction(
            icon: Icons.local_library_rounded,
            label: 'Thư viện',
            color: AppColors.primary,
            onTap: () => nav.selectMenu(NavIndex.book),
          ),
          _QuickAction(
            icon: Icons.history_rounded,
            label: 'Sách đã mượn',
            color: const Color(0xFFF59E0B),
            onTap: () => nav.selectMenu(NavIndex.loan),
          ),
          _QuickAction(
            icon: Icons.bookmark_rounded,
            label: 'Đặt trước',
            color: const Color(0xFFEF4444),
            onTap: () => nav.selectMenu(NavIndex.reservation),
          ),
          _QuickAction(
            icon: Icons.person_outline_rounded,
            label: 'Hồ sơ',
            color: const Color(0xFF06B6D4),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actionsFor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thao tác nhanh',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final action in actions) _QuickActionTile(action: action),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: action.onTap,
        child: Container(
          width: 156,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: action.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: action.color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(action.icon, size: 20, color: action.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: action.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;

    switch (role) {
      case UserRole.admin:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      case UserRole.librarian:
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1E40AF);
        break;
      case UserRole.member:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
