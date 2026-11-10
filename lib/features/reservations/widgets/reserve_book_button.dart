import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../books/domain/entities/book.dart';
import '../models/reservation.dart';
import '../providers/reservation_provider.dart';

/// Nguyen Duy Khang
/// Hiển thị và xử lý nút đặt trước khi sách không còn bản khả dụng.
class ReserveBookButton extends ConsumerStatefulWidget {
  const ReserveBookButton({super.key, required this.book});

  final Book book;

  @override
  ConsumerState<ReserveBookButton> createState() => _ReserveBookButtonState();
}

/// Nguyen Duy Khang
/// Quản lý trạng thái xác nhận, gửi request và thông báo kết quả đặt trước.
class _ReserveBookButtonState extends ConsumerState<ReserveBookButton> {
  bool _isSubmitting = false;

  Future<void> _reserve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đặt trước'),
        content: Text(
          'Sách “${widget.book.title}” đang hết. Bạn có muốn tham gia '
          'hàng chờ không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đặt trước'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final reservation = await ref
          .read(reservationServiceProvider)
          .createReservation(widget.book.id);
      if (!mounted) return;
      // Dừng loading trước khi mở dialog để giao diện không chạy spinner ngầm.
      setState(() => _isSubmitting = false);
      await _showSuccess(reservation);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showSuccess(Reservation reservation) {
    final position = reservation.queuePosition > 0
        ? 'Vị trí hiện tại của bạn: ${reservation.queuePosition}.'
        : 'Yêu cầu của bạn đang được xử lý.';
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Đặt trước thành công'),
        content: Text(
          '$position\nBạn sẽ nhận được thông báo khi sách sẵn sàng.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.book.available > 0) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: _isSubmitting ? null : _reserve,
        icon: _isSubmitting
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.bookmark_add_outlined),
        label: Text(_isSubmitting ? 'Đang đặt trước...' : 'Đặt trước sách'),
      ),
    );
  }
}
