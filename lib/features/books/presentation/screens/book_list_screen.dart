import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/book.dart';
import '../providers/book_provider.dart';
import 'book_add_screen.dart';
import 'book_detail_screen.dart';

class BookListScreen extends ConsumerStatefulWidget {
  const BookListScreen({super.key});

  @override
  ConsumerState<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends ConsumerState<BookListScreen> {
  String _keyword = '';

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bookListProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Danh sách sách', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(tooltip: 'Thêm sách', onPressed: _openAdd, icon: const Icon(Icons.add_circle_outline, color: Color(0xFF3157B7))),
          IconButton(tooltip: 'Làm mới', onPressed: () => ref.invalidate(bookListProvider), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) => setState(() => _keyword = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên sách, tác giả, ISBN...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: booksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(message: error.toString(), onRetry: () => ref.invalidate(bookListProvider)),
            data: (books) {
              final filtered = books.where((book) => '${book.title} ${book.author} ${book.isbn}'.toLowerCase().contains(_keyword)).toList();
              if (filtered.isEmpty) return Center(child: Text(books.isEmpty ? 'Chưa có sách nào.' : 'Không tìm thấy sách phù hợp.'));
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(bookListProvider);
                  await ref.read(bookListProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _BookCard(book: filtered[index]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _openAdd() async {
    final added = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const BookAddScreen()));
    if (added == true && mounted) {
      ref.invalidate(bookListProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm sách thành công.'), backgroundColor: Colors.green));
    }
  }
}

class _BookCard extends ConsumerWidget {
  const _BookCard({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = book.available > 0;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE6EAF0))),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(radius: 27, backgroundColor: const Color(0xFFE6EDFF), child: Text(book.title.isEmpty ? '?' : book.title[0].toUpperCase(), style: const TextStyle(color: Color(0xFF3157B7), fontSize: 21, fontWeight: FontWeight.bold))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(book.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('Tác giả: ${book.author}'),
              const SizedBox(height: 5),
              Text('ISBN: ${book.isbn}'),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: available ? const Color(0xFFE2F6E9) : const Color(0xFFFFE9E7), borderRadius: BorderRadius.circular(20)), child: Text(available ? 'Còn ${book.available} cuốn' : 'Hết sách', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: available ? const Color(0xFF16713A) : const Color(0xFFB42318)))),
            ])),
            IconButton(tooltip: 'Sửa sách', icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () async {
              final updated = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => BookAddScreen(book: book)));
              if (updated == true && context.mounted) ref.invalidate(bookListProvider);
            }),
            IconButton(tooltip: 'Xóa sách', icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _delete(context, ref)),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final approved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Xác nhận xóa'), content: Text('Bạn có chắc muốn xóa sách "${book.title}" không?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Xóa'))]));
    if (approved != true) return;
    await ref.read(bookRepositoryProvider).deleteBook(book.id);
    ref.invalidate(bookListProvider);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa sách.'), backgroundColor: Colors.green));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 52, color: Colors.redAccent), const SizedBox(height: 12), const Text('Không thể tải danh sách sách', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(message, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại'))])));
}
