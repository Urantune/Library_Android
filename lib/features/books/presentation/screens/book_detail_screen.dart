import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/book.dart';
import '../providers/book_provider.dart';
import 'book_add_screen.dart';
import '../widgets/book_copies_section.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.bookId});
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookDetailProvider(bookId));
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Chi tiết sách'),
        backgroundColor: Colors.white,
        actions: [
          bookAsync.maybeWhen(
            data: (book) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    tooltip: 'Sửa sách',
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _edit(context, ref, book)),
                IconButton(
                    tooltip: 'Xóa sách',
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _delete(context, ref, book)),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Không thể tải chi tiết sách.'),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: () => ref.invalidate(bookDetailProvider(bookId)),
              child: const Text('Thử lại')),
        ])),
        data: (book) => ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE6EAF0))),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                if (book.coverUrl.isNotEmpty)
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(book.coverUrl, width: 100, height: 140, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.menu_book, size: 64)))
                else CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFFE6EDFF),
                    child: Text(
                        book.title.isEmpty ? '?' : book.title[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3157B7)))),
                const SizedBox(height: 12),
                Text(book.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(book.author,
                    style: const TextStyle(color: Colors.black54)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE6EAF0))),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thông tin sách',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _row('Tác giả', book.author),
                    _row('Thể loại', book.category),
                    _row('Nhà xuất bản', book.publisher),
                    _row('ISBN', book.isbn),
                    _row('Mã đầu sách', book.id),
                    _row('Năm xuất bản', '${book.year}'),
                    _row('Ngôn ngữ', book.language.isEmpty ? 'Chưa có' : book.language),
                    _row('Số trang', book.pageCount?.toString() ?? 'Chưa có'),
                    _row('Số lượng', '${book.available}/${book.quantity}'),
                    if (book.description.isNotEmpty) ...[
                      const Divider(height: 28),
                      Text(book.description)
                    ],
                  ]),
            ),
          ),
          const SizedBox(height: 16),
          BookCopiesSection(bookId: bookId),
        ]),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.black54))),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)))
      ]));

  Future<void> _edit(BuildContext context, WidgetRef ref, Book book) async {
    final updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => BookAddScreen(book: book)));
    if (updated == true) {
      ref.invalidate(bookPagedProvider);
      ref.invalidate(bookListProvider);
      ref.invalidate(bookDetailProvider(book.id));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Book book) async {
    final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Xác nhận xóa'),
                content:
                    Text('Bạn có chắc muốn xóa sách "${book.title}" không?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy')),
                  FilledButton(
                      style:
                          FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xóa'))
                ]));
    if (approved != true) return;
    try {
      await ref.read(bookRepositoryProvider).deleteBook(book.id);
      ref.invalidate(bookPagedProvider);
      ref.invalidate(bookListProvider);
      ref.invalidate(bookDetailProvider(book.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đã xóa sách.'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
