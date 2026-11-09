import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/books/domain/entities/book.dart';
import '../../features/books/presentation/providers/book_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import 'library_book_detail_screen.dart';

/// "Thư viện" dành cho bạn đọc: xem và tìm sách, không có thao tác quản trị.
///
/// Chỉ đọc dữ liệu từ `bookListProvider` của module books (Khang),
/// không sửa code module books.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Book> _filter(List<Book> books) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return books;
    return books.where((book) {
      final text = '${book.title} ${book.author} ${book.category} ${book.isbn}'
          .toLowerCase();
      return text.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bookListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Thư viện',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () => ref.invalidate(bookListProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên sách, tác giả, thể loại, ISBN...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE1E6ED)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE1E6ED)),
                ),
              ),
            ),
          ),
          Expanded(
            child: booksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _LibraryError(
                message: error.toString(),
                onRetry: () => ref.invalidate(bookListProvider),
              ),
              data: (books) {
                final visible = _filter(books);
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      books.isEmpty
                          ? 'Thư viện chưa có sách nào.'
                          : 'Không tìm thấy sách phù hợp.',
                    ),
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${visible.length} sách',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(bookListProvider);
                          await ref.read(bookListProvider.future);
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              _LibraryBookCard(book: visible[index]),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryBookCard extends StatelessWidget {
  final Book book;

  const _LibraryBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final available = book.available > 0;

    return Container(
      decoration: cardDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LibraryBookDetailScreen(bookId: book.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE6EDFF),
                child: Text(
                  book.title.isEmpty ? '?' : book.title[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF3157B7),
                    fontSize: 20,
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
                      book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                    if (book.category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: available
                            ? const Color(0xFFE2F6E9)
                            : const Color(0xFFFFE9E7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        available ? 'Còn ${book.available} cuốn' : 'Hết sách',
                        style: TextStyle(
                          fontSize: 11,
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
              const Icon(Icons.chevron_right, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LibraryError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 52, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Không thể tải thư viện',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
}
