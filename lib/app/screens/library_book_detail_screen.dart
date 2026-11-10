import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/books/domain/entities/book.dart';
import '../../features/books/presentation/providers/book_provider.dart';
import '../theme/app_colors.dart';

/// Chi tiết sách ở chế độ chỉ đọc dành cho bạn đọc.
class LibraryBookDetailScreen extends ConsumerWidget {
  final String bookId;

  const LibraryBookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookDetailProvider(bookId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết sách'),
        backgroundColor: Colors.white,
      ),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 52, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text('Không thể tải chi tiết sách.'),
                const SizedBox(height: 8),
                const Text('Vui lòng kiểm tra kết nối và thử lại.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(bookDetailProvider(bookId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (book) => _BookDetail(book: book),
      ),
    );
  }
}

class _BookDetail extends StatelessWidget {
  final Book book;

  const _BookDetail({required this.book});

  @override
  Widget build(BuildContext context) {
    final available = book.available > 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EAF0)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFE6EDFF),
                child: Text(
                  book.title.isEmpty ? '?' : book.title[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3157B7),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                book.author,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: available
                      ? const Color(0xFFE2F6E9)
                      : const Color(0xFFFFE9E7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  available ? 'Còn ${book.available} cuốn' : 'Hết sách',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: available
                        ? const Color(0xFF16713A)
                        : const Color(0xFFB42318),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EAF0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin sách',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _InfoRow(label: 'Tác giả', value: book.author),
              _InfoRow(label: 'Thể loại', value: book.category),
              _InfoRow(label: 'Nhà xuất bản', value: book.publisher),
              _InfoRow(label: 'ISBN', value: book.isbn),
              _InfoRow(label: 'Năm xuất bản', value: '${book.year}'),
              _InfoRow(
                label: 'Số lượng',
                value: '${book.available}/${book.quantity}',
              ),
              if (book.description.isNotEmpty) ...[
                const Divider(height: 28),
                Text(book.description),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCE6FA)),
          ),
          child: const Row(
            children: [
              Icon(Icons.support_agent, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Liên hệ thủ thư để mượn sách. Chức năng mượn trực tuyến '
                  'sẽ được bổ sung khi API circulation sẵn sàng.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
