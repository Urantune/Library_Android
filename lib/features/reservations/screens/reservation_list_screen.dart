import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/presentation/providers/book_provider.dart';
import '../models/reservation.dart';
import '../providers/reservation_provider.dart';

/// Nguyen Duy Khang
/// Hiển thị lịch sử, trạng thái và thao tác hủy lượt đặt trước của tài khoản.
class ReservationListScreen extends ConsumerWidget {
  const ReservationListScreen({super.key});

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    Reservation reservation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đặt trước?'),
        content: const Text(
          'Bạn sẽ rời khỏi hàng chờ của sách này. Thao tác không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đặt trước'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(reservationServiceProvider)
          .cancelReservation(reservation.id);
      ref.invalidate(myReservationsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy lượt đặt trước.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(myReservationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đặt trước sách',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Theo dõi vị trí hàng chờ và tình trạng nhận sách',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref.invalidate(myReservationsProvider),
                  tooltip: 'Tải lại',
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: reservations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ReservationError(
                message: error.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(myReservationsProvider),
              ),
              data: (items) {
                if (items.isEmpty) return const _EmptyReservations();
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(myReservationsProvider.future),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ReservationCard(
                      reservation: items[index],
                      onCancel: () => _cancel(context, ref, items[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Nguyen Duy Khang
/// Hiển thị thông tin một lượt đặt trước và nút hủy khi còn hiệu lực.
class _ReservationCard extends ConsumerWidget {
  const _ReservationCard({
    required this.reservation,
    required this.onCancel,
  });

  final Reservation reservation;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(bookDetailProvider(reservation.bookId));
    final title = book.when(
      data: (value) => value.title,
      loading: () => 'Đang tải tên sách...',
      error: (_, __) => 'Sách ${reservation.bookId}',
    );
    final active =
        reservation.status == 'WAITING' || reservation.status == 'READY';
    final style = _statusStyle(reservation.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bookmark_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(label: style.label, color: style.color),
                    if (reservation.status == 'WAITING' &&
                        reservation.queuePosition > 0)
                      _InfoChip(
                        icon: Icons.groups_outlined,
                        label: 'Vị trí ${reservation.queuePosition}',
                      ),
                    if (reservation.status == 'READY')
                      const _InfoChip(
                        icon: Icons.check_circle_outline,
                        label: 'Có thể đến nhận',
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Ngày đặt: ${_formatDate(reservation.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (reservation.expiresAt != null)
                  Text(
                    'Hạn nhận: ${_formatDate(reservation.expiresAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB45309),
                    ),
                  ),
              ],
            ),
          ),
          if (active)
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hủy'),
            ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return 'Chưa cập nhật';
    final local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  static ({String label, Color color}) _statusStyle(String status) {
    return switch (status) {
      'WAITING' => (label: 'Đang chờ', color: const Color(0xFFF59E0B)),
      'READY' => (label: 'Sẵn sàng', color: const Color(0xFF16A34A)),
      'FULFILLED' => (label: 'Đã nhận sách', color: const Color(0xFF2563EB)),
      'CANCELLED' => (label: 'Đã hủy', color: const Color(0xFF64748B)),
      'EXPIRED' => (label: 'Đã hết hạn', color: const Color(0xFFDC2626)),
      _ => (label: status, color: const Color(0xFF64748B)),
    };
  }
}

/// Nguyen Duy Khang
/// Hiển thị nhãn trạng thái bằng màu tương ứng.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

/// Nguyen Duy Khang
/// Hiển thị thông tin ngắn như vị trí hàng chờ hoặc trạng thái nhận sách.
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF475569)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
          ],
        ),
      );
}

/// Nguyen Duy Khang
/// Hiển thị hướng dẫn khi tài khoản chưa có lượt đặt trước.
class _EmptyReservations extends StatelessWidget {
  const _EmptyReservations();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark_border_rounded,
                size: 56,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: 14),
              Text(
                'Bạn chưa có lượt đặt trước nào',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Mở chi tiết một sách đang hết hàng để tham gia hàng chờ.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
}

/// Nguyen Duy Khang
/// Hiển thị lỗi tải danh sách và cho phép thử lại.
class _ReservationError extends StatelessWidget {
  const _ReservationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 52, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'Không thể tải danh sách đặt trước',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
}
