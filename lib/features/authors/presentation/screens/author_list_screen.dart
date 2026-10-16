import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/author.dart';
import '../providers/author_provider.dart';
import '../../../books/presentation/providers/book_provider.dart';
import 'author_detail_screen.dart';
import 'author_add_screen.dart';

class AuthorListScreen extends ConsumerStatefulWidget {
  const AuthorListScreen({super.key});

  @override
  ConsumerState<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends ConsumerState<AuthorListScreen> {
  String keyword = '';
  int _page = 0;
  static const int _pageSize = 5;

  @override
  Widget build(BuildContext context) {
    final authorsAsync = ref.watch(authorListProvider);
    final booksAsync = ref.watch(bookListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Tác giả',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () {
              ref.invalidate(authorListProvider);
              ref.invalidate(bookListProvider);
            },
            icon: const Icon(Icons.notifications_none, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          keyword = value.trim().toLowerCase();
                          _page = 0;
                        });
                      },
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên tác giả...',
                        hintStyle: const TextStyle(
                            fontSize: 12, color: Color(0xFF8993A4)),
                        prefixIcon: const Icon(Icons.search,
                            size: 17, color: Color(0xFF8490A2)),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 34),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide:
                              const BorderSide(color: Color(0xFFE1E6ED)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide:
                              const BorderSide(color: Color(0xFFE1E6ED)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 38,
                  child: FilledButton.icon(
                    onPressed: _addAuthor,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm tác giả',
                        style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0878F9),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: authorsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => _ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(authorListProvider),
              ),
              data: (authors) {
                final filtered = authors.where((author) {
                  return author.name.toLowerCase().contains(keyword);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      authors.isEmpty
                          ? 'Chưa có tác giả nào.'
                          : 'Không tìm thấy tác giả phù hợp.',
                    ),
                  );
                }

                final pageCount = (filtered.length / _pageSize).ceil();
                final currentPage = _page.clamp(0, pageCount - 1);
                final pageAuthors = filtered
                    .skip(currentPage * _pageSize)
                    .take(_pageSize)
                    .toList();
                final bookCounts = booksAsync.maybeWhen(
                  data: (books) {
                    final counts = <String, int>{};
                    for (final book in books) {
                      final key = book.author.trim().toLowerCase();
                      counts.update(key, (count) => count + 1,
                          ifAbsent: () => 1);
                    }
                    return counts;
                  },
                  orElse: () => const <String, int>{},
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(authorListProvider);
                    ref.invalidate(bookListProvider);
                    await ref.read(authorListProvider.future);
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _AuthorTable(
                          authors: pageAuthors,
                          firstIndex: currentPage * _pageSize,
                          bookCounts: bookCounts,
                        ),
                      ),
                      _Pagination(
                        currentPage: currentPage,
                        pageCount: pageCount,
                        onPageChanged: (page) => setState(() => _page = page),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addAuthor() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AuthorAddScreen()),
    );
    if (added == true && mounted) {
      ref.invalidate(authorListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Thêm tác giả thành công!'),
            backgroundColor: Colors.green),
      );
    }
  }
}

class _AuthorTable extends StatelessWidget {
  final List<Author> authors;
  final int firstIndex;
  final Map<String, int> bookCounts;

  const _AuthorTable({
    required this.authors,
    required this.firstIndex,
    required this.bookCounts,
  });

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(color: Color(0xFFE5E9EF));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E6ED)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Container(
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              border: Border(bottom: border),
            ),
            child: const _AuthorTableCells(
              children: [
                _TableCell('#',
                    alignment: Alignment.center,
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                _TableCell('Ảnh',
                    alignment: Alignment.center,
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                _TableCell('Tên tác giả',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                _TableCell('Quốc tịch',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                _TableCell('Số sách',
                    alignment: Alignment.center,
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                _TableCell('Thao tác',
                    alignment: Alignment.center,
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          for (var index = 0; index < authors.length; index++)
            _AuthorRow(
              author: authors[index],
              rowNumber: firstIndex + index + 1,
              bookCount:
                  bookCounts[authors[index].name.trim().toLowerCase()] ?? 0,
              isLast: index == authors.length - 1,
            ),
        ],
      ),
    );
  }
}

class _AuthorRow extends ConsumerWidget {
  final Author author;
  final int rowNumber;
  final int bookCount;
  final bool isLast;

  const _AuthorRow({
    required this.author,
    required this.rowNumber,
    required this.bookCount,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => AuthorDetailScreen(authorId: author.id)),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFE9EDF2))),
        ),
        child: _AuthorTableCells(
          children: [
            _TableCell('$rowNumber', alignment: Alignment.center),
            _TableCell(
              '',
              alignment: Alignment.center,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: const Color(0xFFE6EDF8),
                child: Text(
                  author.name.isEmpty ? '?' : author.name[0].toUpperCase(),
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF345B8C)),
                ),
              ),
            ),
            _TableCell(
              author.name.isEmpty ? 'Chưa có tên' : author.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            _TableCell(_display(author.country)),
            _TableCell('$bookCount', alignment: Alignment.center),
            _TableCell(
              '',
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionIcon(
                    tooltip: 'Chi tiết',
                    icon: Icons.visibility_outlined,
                    color: const Color(0xFF1680F8),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              AuthorDetailScreen(authorId: author.id)),
                    ),
                  ),
                  _ActionIcon(
                    tooltip: 'Sửa tác giả',
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF1680F8),
                    onPressed: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                            builder: (_) => AuthorAddScreen(author: author)),
                      );
                      if (updated == true && context.mounted) {
                        ref.invalidate(authorListProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Cập nhật tác giả thành công!'),
                              backgroundColor: Colors.green),
                        );
                      }
                    },
                  ),
                  _ActionIcon(
                    tooltip: 'Xóa tác giả',
                    icon: Icons.delete_outline,
                    color: const Color(0xFFE5483B),
                    onPressed: () => _deleteAuthor(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAuthor(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content:
            Text('Bạn có chắc chắn muốn xóa tác giả "${author.name}" không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(authorRepositoryProvider).deleteAuthor(author.id);
      ref.invalidate(authorListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã xóa tác giả thành công!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Không thể xóa tác giả: $error'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _AuthorTableCells extends StatelessWidget {
  final List<_TableCell> children;

  const _AuthorTableCells({required this.children});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(30),
        1: FixedColumnWidth(38),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(2),
        4: FixedColumnWidth(46),
        5: FixedColumnWidth(96),
      },
      children: [
        TableRow(
          children: children.map((cell) => cell.build(context)).toList(),
        ),
      ],
    );
  }
}

class _TableCell {
  final String text;
  final Alignment alignment;
  final TextStyle? style;
  final Widget? child;

  const _TableCell(
    this.text, {
    this.alignment = Alignment.centerLeft,
    this.style,
    this.child,
  });

  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Align(
          alignment: alignment,
          child: child ??
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style ??
                      const TextStyle(fontSize: 13, color: Color(0xFF344054)),
                ),
              ),
        ),
      );
}

class _ActionIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionIcon({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 17, color: color),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 40),
        visualDensity: VisualDensity.compact,
      );
}

class _Pagination extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final ValueChanged<int> onPageChanged;

  const _Pagination({
    required this.currentPage,
    required this.pageCount,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _PageButton(
            icon: Icons.chevron_left,
            enabled: currentPage > 0,
            onPressed: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 4),
          for (var page = 0; page < pageCount; page++) ...[
            _PageNumber(
              number: page + 1,
              selected: page == currentPage,
              onPressed: () => onPageChanged(page),
            ),
            if (page != pageCount - 1) const SizedBox(width: 4),
          ],
          const SizedBox(width: 4),
          _PageButton(
            icon: Icons.chevron_right,
            enabled: currentPage < pageCount - 1,
            onPressed: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PageButton(
      {required this.icon, required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 28,
        height: 28,
        child: OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero, minimumSize: Size.zero),
          child: Icon(icon, size: 16),
        ),
      );
}

class _PageNumber extends StatelessWidget {
  final int number;
  final bool selected;
  final VoidCallback onPressed;

  const _PageNumber(
      {required this.number, required this.selected, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 28,
        height: 28,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            backgroundColor: selected ? const Color(0xFFEAF3FF) : Colors.white,
            foregroundColor:
                selected ? const Color(0xFF0878F9) : const Color(0xFF596579),
            side: BorderSide(
                color: selected
                    ? const Color(0xFF1680F8)
                    : const Color(0xFFE1E6ED)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: Text('$number', style: const TextStyle(fontSize: 11)),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

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
              'Không thể tải danh sách tác giả',
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

String _display(String? value) =>
    value == null || value.trim().isEmpty ? 'Chưa cập nhật' : value;

String _formatDate(DateTime? date) {
  if (date == null) return 'Chưa cập nhật';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
