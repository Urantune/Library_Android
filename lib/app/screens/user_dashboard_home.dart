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
    final user =
        ref.watch(authControllerProvider.select((state) => state.user));
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
            if (userId.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionTitle('Sách đang mượn'),
              const SizedBox(height: 12),
              _BorrowedBooksSection(
                loans: loans!,
                onRetry: () => ref.invalidate(borrowedLoansProvider(userId)),
              ),
            ],
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
          value = '${_borrowedBookCount(page.content)}';
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

  static int _borrowedBookCount(List<LoanResponseDTO> loans) => loans
      .where((loan) => loan.status.toUpperCase() == 'BORROWED')
      .fold(0, (count, loan) => count + loan.items.length);

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
      onTap: () => context.read<NavigationProvider>().selectMenu(NavIndex.book),
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

class _BorrowedBooksSection extends StatelessWidget {
  const _BorrowedBooksSection({
    required this.loans,
    required this.onRetry,
  });

  final AsyncValue<PageDTO<LoanResponseDTO>> loans;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return loans.when(
      loading: () => const _BorrowedBooksContainer(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (_, __) => _BorrowedBooksContainer(
        child: ListTile(
          leading: const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          title: const Text('Không tải được danh sách sách đang mượn.'),
          trailing: TextButton(
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ),
      ),
      data: (page) {
        final borrowedLoans = page.content
            .where((loan) => loan.status.toUpperCase() == 'BORROWED')
            .toList();
        final bookCount = borrowedLoans.fold<int>(
          0,
          (count, loan) => count + loan.items.length,
        );

        if (bookCount == 0) {
          return const _BorrowedBooksContainer(
            child: ListTile(
              leading: Icon(
                Icons.menu_book_outlined,
                color: Color(0xFF64748B),
              ),
              title: Text('Bạn chưa có sách đang mượn.'),
            ),
          );
        }

        return _BorrowedBooksContainer(
          child: Column(
            children: [
              for (final loan in borrowedLoans)
                for (var index = 0; index < loan.items.length; index++)
                  _BorrowedBookRow(
                    item: loan.items[index],
                    loanId: loan.id,
                    loanStatus: loan.status,
                    dueAt: loan.dueAt,
                    showDivider: index > 0 || borrowedLoans.first != loan,
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _BorrowedBooksContainer extends StatelessWidget {
  const _BorrowedBooksContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

class _BorrowedBookRow extends StatelessWidget {
  const _BorrowedBookRow({
    required this.item,
    required this.loanId,
    required this.loanStatus,
    required this.dueAt,
    required this.showDivider,
  });

  final Map<String, dynamic> item;
  final String loanId;
  final String loanStatus;
  final DateTime? dueAt;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final nestedBook = item['book'];
    final title = item['bookTitle'] ??
        item['bookName'] ??
        item['title'] ??
        (nestedBook is Map ? nestedBook['title'] : null);
    final bookId = item['bookId'] ?? item['id'];
    final displayTitle = title?.toString().trim();
    final heading = displayTitle != null && displayTitle.isNotEmpty
        ? displayTitle
        : bookId != null
            ? 'Sách $bookId'
            : 'Sách chưa có tên';
    final dueDateLabel =
        dueAt == null ? 'Chưa có hạn trả' : 'Hạn trả ${_formatDate(dueAt!)}';

    return Column(
      children: [
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          title: Text(
            heading,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            '$dueDateLabel · Phiếu $loanId',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => _BorrowedBookDetailsDialog(
              title: heading,
              item: item,
              loanId: loanId,
              loanStatus: loanStatus,
              dueAt: dueAt,
            ),
          ),
        ),
      ],
    );
  }
}

class _BorrowedBookDetailsDialog extends StatelessWidget {
  const _BorrowedBookDetailsDialog({
    required this.title,
    required this.item,
    required this.loanId,
    required this.loanStatus,
    required this.dueAt,
  });

  final String title;
  final Map<String, dynamic> item;
  final String loanId;
  final String loanStatus;
  final DateTime? dueAt;

  @override
  Widget build(BuildContext context) {
    final returnedAt = item['returnedAt']?.toString();
    final conditionOnReturn = item['conditionOnReturn']?.toString();
    final fineAmount = item['fineAmount'];

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BookDetailRow('Mã phiếu', loanId),
            _BookDetailRow('Trạng thái phiếu', loanStatus),
            _BookDetailRow(
              'Mã mục mượn',
              item['id']?.toString() ?? 'Chưa có',
            ),
            _BookDetailRow(
              'Mã sách',
              item['bookId']?.toString() ?? 'Chưa có',
            ),
            _BookDetailRow(
              'Mã bản sao',
              item['copyId']?.toString() ?? 'Chưa có',
            ),
            _BookDetailRow(
              'Trạng thái sách',
              item['itemStatus']?.toString() ?? 'Chưa có',
            ),
            _BookDetailRow(
              'Hạn trả',
              dueAt == null ? 'Chưa có' : _formatDate(dueAt!),
            ),
            if (returnedAt != null && returnedAt.isNotEmpty)
              _BookDetailRow('Ngày trả', returnedAt),
            if (conditionOnReturn != null && conditionOnReturn.isNotEmpty)
              _BookDetailRow('Tình trạng khi trả', conditionOnReturn),
            if (fineAmount != null)
              _BookDetailRow('Tiền phạt', fineAmount.toString()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _BookDetailRow extends StatelessWidget {
  const _BookDetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
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
                    color:
                        hasError ? const Color(0xFFDC2626) : AppColors.primary,
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

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
