import 'dart:async';
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
  const LibraryScreen({super.key, this.initialQuery = ''});
  final String initialQuery;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late final TextEditingController _searchController;
  String _query = '';
  int _page = 0;
  bool _availableOnly = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = BookQuery(page: _page, size: 20, query: _query, copyStatus: _availableOnly ? 'AVAILABLE' : null);
    final booksAsync = ref.watch(bookPagedProvider(query));

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
            onPressed: () => ref.invalidate(bookPagedProvider(query)),
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
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) setState(() { _query = value.trim(); _page = 0; });
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm theo tên sách, tác giả, thể loại, ISBN...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          _debounce?.cancel();
                          setState(() { _query = ''; _page = 0; });
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(alignment: Alignment.centerLeft, child: FilterChip(
              label: const Text('Còn sách'), selected: _availableOnly,
              onSelected: (value) => setState(() { _availableOnly = value; _page = 0; }),
            )),
          ),
          Expanded(
            child: booksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _LibraryError(
                message: 'Vui lòng kiểm tra kết nối và thử lại.',
                onRetry: () => ref.invalidate(bookPagedProvider(query)),
              ),
              data: (result) {
                final visible = result.items;
                if (visible.isEmpty) {
                  return Center(
                    child: Text(
                      _query.isEmpty && !_availableOnly ? 'Thư viện chưa có sách nào.' : 'Không tìm thấy sách phù hợp.',
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
                          '${result.totalElements} sách',
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
                          ref.invalidate(bookPagedProvider(query));
                          await ref.read(bookPagedProvider(query).future);
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
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconButton(tooltip: 'Trang trước', onPressed: _page > 0 ? () => setState(() => _page--) : null, icon: const Icon(Icons.chevron_left)),
                      Text('Trang ${result.page + 1}/${result.totalPages}'),
                      IconButton(tooltip: 'Trang sau', onPressed: _page + 1 < result.totalPages ? () => setState(() => _page++) : null, icon: const Icon(Icons.chevron_right)),
                    ]),
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
