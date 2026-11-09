import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' show ReadContext;

import '../../features/loans/data/models/loan_response.dart';
import '../../features/loans/presentation/providers/loan_provider.dart';
import '../../features/loans/presentation/screens/borrowed_loans_screen.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/sign/controllers/auth_controller.dart';
import '../../features/sign/models/user.dart' as auth;
import '../../features/users/presentation/screens/profile_screen.dart';
import '../models/user_role.dart';
import '../providers/dashboard_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/dashboard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../widgets/inventory_books_section.dart';
import '../widgets/skeleton.dart';

/// Trang chủ dành cho độc giả (vai trò MEMBER/USER).
///
/// Chỉ hiển thị dữ liệu thật từ API. Khi API lỗi thì hiện trạng thái lỗi và
/// nút thử lại, không dùng số liệu giả.
class UserDashboardHome extends ConsumerWidget {
  const UserDashboardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.select((state) => state.user));
    final userId = user?.id ?? '';
    final loans =
        userId.isEmpty ? null : ref.watch(borrowedLoansProvider(userId));
    final books = ref.watch(booksOverviewProvider);
    final name = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : 'bạn';

    return RefreshIndicator(
      onRefresh: () => _refresh(ref, userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào, $name',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _todayLabel(DateTime.now()),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            _ProfileCard(user: user),
            const SizedBox(height: 24),
            const _SectionTitle('Hoạt động của tôi'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 12.0;
                final columns = constraints.maxWidth >= 720 ? 3 : 1;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                final cards = <Widget>[
                  _loansCard(context, ref, loans, userId),
                  _booksCard(context, ref, books),
                  _accountCard(context, user),
                ];
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final card in cards)
                      SizedBox(width: width, child: card),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Truy cập nhanh'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickAction(
                  icon: Icons.search_rounded,
                  label: 'Tìm sách',
                  color: const Color(0xFF2563EB),
                  onTap: () => context
                      .read<NavigationProvider>()
                      .selectMenu(NavIndex.book),
                ),
                _QuickAction(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Mượn - trả',
                  color: const Color(0xFF0891B2),
                  onTap: () => _open(context, const BorrowedLoansScreen()),
                ),
                _QuickAction(
                  icon: Icons.notifications_none_rounded,
                  label: 'Thông báo',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _open(context, const NotificationListScreen()),
                ),
                _QuickAction(
                  icon: Icons.person_outline_rounded,
                  label: 'Hồ sơ',
                  color: const Color(0xFF16A34A),
                  onTap: () => _open(context, const ProfileScreen()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const InventoryBooksSection(),
          ],
        ),
      ),
    );
  }

  Widget _loansCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<PageDTO<LoanResponseDTO>>? loans,
    String userId,
  ) {
    String? value;
    var loading = true;
    var hasError = false;

    if (loans == null) {
      loading = false;
      value = '—';
    } else {
      loans.when(
        data: (page) {
          loading = false;
          value = '${page.totalElements}';
        },
        loading: () {},
        error: (_, __) {
          loading = false;
          hasError = true;
        },
      );
    }

    return _MetricCard(
      icon: Icons.menu_book_rounded,
      color: const Color(0xFF2563EB),
      label: 'Sách đang mượn',
      value: value,
      loading: loading,
      hasError: hasError,
      hint: hasError ? 'Chạm để tải lại' : 'Xem phiếu mượn',
      onTap: () => _open(context, const BorrowedLoansScreen()),
      onRetry: () {
        if (userId.isNotEmpty) ref.invalidate(borrowedLoansProvider(userId));
      },
    );
  }

  Widget _booksCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<BooksOverview> books,
  ) {
    String? value;
    var loading = true;
    var hasError = false;

    books.when(
      data: (overview) {
        loading = false;
        value = '${overview.total}';
      },
      loading: () {},
      error: (_, __) {
        loading = false;
        hasError = true;
      },
    );

    return _MetricCard(
      icon: Icons.local_library_rounded,
      color: const Color(0xFFF59E0B),
      label: 'Sách trong thư viện',
      value: value,
      loading: loading,
      hasError: hasError,
      hint: hasError ? 'Chạm để tải lại' : 'Xem danh sách',
      onTap: () =>
          context.read<NavigationProvider>().selectMenu(NavIndex.book),
      onRetry: () => ref.invalidate(booksOverviewProvider),
    );
  }

  Widget _accountCard(BuildContext context, auth.User? user) {
    final status = (user?.status ?? '').trim().toUpperCase();
    final active = status == 'ACTIVE';
    return _MetricCard(
      icon: Icons.verified_user_rounded,
      color: active ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      label: 'Trạng thái tài khoản',
      value: status.isEmpty ? '—' : (active ? 'Hoạt động' : status),
      loading: false,
      hasError: false,
      hint: 'Xem hồ sơ',
      onTap: () => _open(context, const ProfileScreen()),
      onRetry: () {},
    );
  }

  Future<void> _refresh(WidgetRef ref, String userId) async {
    ref.invalidate(booksOverviewProvider);
    if (userId.isNotEmpty) ref.invalidate(borrowedLoansProvider(userId));

    Future<void> settle(Future<Object?> future) =>
        future.then<void>((_) {}, onError: (_) {});

    await Future.wait([
      settle(ref.read(booksOverviewProvider.future)),
      if (userId.isNotEmpty)
        settle(ref.read(borrowedLoansProvider(userId).future)),
    ]);
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  static String _todayLabel(DateTime date) {
    const weekdays = [
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
      'Chủ nhật',
    ];
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '${weekdays[date.weekday - 1]}, $dd/$mm/${date.year}';
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final auth.User? user;

  @override
  Widget build(BuildContext context) {
    final name = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : 'Người dùng';
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final active = (user?.status ?? '').toUpperCase() == 'ACTIVE';
    final roles = user?.roles ?? const <String>[];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE6EDFF),
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF3157B7),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      text: _roleOf(roles),
                      background: const Color(0xFFEFF6FF),
                      foreground: const Color(0xFF1E40AF),
                    ),
                    _Chip(
                      text: active ? 'Đang hoạt động' : 'Tạm khóa',
                      background: active
                          ? const Color(0xFFE2F6E9)
                          : const Color(0xFFFFE9E7),
                      foreground: active
                          ? const Color(0xFF16713A)
                          : const Color(0xFFB42318),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: const Text('Hồ sơ'),
          ),
        ],
      ),
    );
  }

  static String _roleOf(List<String> roles) {
    if (roles.isEmpty) return 'Độc giả';
    final role = roles.first.toUpperCase();
    if (role == 'MEMBER' || role == 'USER') return 'Độc giả';
    return roleLabel(role);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.loading,
    required this.hasError,
    required this.hint,
    required this.onTap,
    required this.onRetry,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String? value;
  final bool loading;
  final bool hasError;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : (hasError ? onRetry : onTap),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 34,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: loading
                        ? const Skeleton(width: 64, height: 26)
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value ?? '—',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: hasError
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loading ? '' : hint,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasError ? const Color(0xFFDC2626) : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: cardDecoration(),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
