import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/book.dart';
import '../providers/book_provider.dart';

class BookListScreen extends ConsumerStatefulWidget {
  const BookListScreen({super.key});

  @override
  ConsumerState<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends ConsumerState<BookListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(bookListProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF3)),
        ),
        child: books.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(onRetry: () => ref.invalidate(bookListProvider)),
          data: (items) {
            final filtered = items.where((book) {
              final text = '${book.title} ${book.author} ${book.category} ${book.isbn}'.toLowerCase();
              return text.contains(_query.toLowerCase());
            }).toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: Color(0xFF1E293B)),
                      const SizedBox(width: 8),
                      const Text('Sách', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(onPressed: () => ref.invalidate(bookListProvider), icon: const Icon(Icons.refresh_rounded)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() => _query = value.trim()),
                          decoration: _inputDecoration('Tìm theo tên sách, tác giả, thể loại...', Icons.search),
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: () => _showEditor(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm sách'),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Chưa có sách phù hợp.'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStatePropertyAll(const Color(0xFFF8FAFC)),
                            columns: const [
                              DataColumn(label: Text('#')),
                              DataColumn(label: Text('Tên sách')),
                              DataColumn(label: Text('Tác giả')),
                              DataColumn(label: Text('Thể loại')),
                              DataColumn(label: Text('Năm XB')),
                              DataColumn(label: Text('Trạng thái')),
                              DataColumn(label: Text('Thao tác')),
                            ],
                            rows: [
                              for (var index = 0; index < filtered.length; index++)
                                DataRow(cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(SizedBox(width: 190, child: Text(filtered[index].title, overflow: TextOverflow.ellipsis))),
                                  DataCell(Text(filtered[index].author)),
                                  DataCell(Text(filtered[index].category)),
                                  DataCell(Text('${filtered[index].year}')),
                                  DataCell(_AvailabilityChip(book: filtered[index])),
                                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(tooltip: 'Chi tiết', onPressed: () => _showDetail(context, filtered[index]), icon: const Icon(Icons.visibility_outlined, color: Color(0xFF2563EB))),
                                    IconButton(tooltip: 'Sửa', onPressed: () => _showEditor(context, book: filtered[index]), icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB))),
                                    IconButton(tooltip: 'Xóa', onPressed: () => _confirmDelete(context, filtered[index]), icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444))),
                                  ])),
                                ]),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showEditor(BuildContext context, {Book? book}) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController(text: book?.title);
    final author = TextEditingController(text: book?.author);
    final category = TextEditingController(text: book?.category);
    final publisher = TextEditingController(text: book?.publisher);
    final isbn = TextEditingController(text: book?.isbn);
    final year = TextEditingController(text: book?.year.toString());
    final quantity = TextEditingController(text: book?.quantity.toString());
    final available = TextEditingController(text: book?.available.toString());
    final description = TextEditingController(text: book?.description);
    final result = await showDialog<Book>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book == null ? 'Thêm sách mới' : 'Cập nhật sách'),
        content: SizedBox(
          width: 620,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _EditorField(controller: title, label: 'Tên sách', required: true, wide: true),
                  _EditorField(controller: author, label: 'Tác giả', required: true),
                  _EditorField(controller: category, label: 'Thể loại', required: true),
                  _EditorField(controller: publisher, label: 'Nhà xuất bản', required: true),
                  _EditorField(controller: isbn, label: 'ISBN', required: true),
                  _EditorField(controller: year, label: 'Năm xuất bản', number: true),
                  _EditorField(controller: quantity, label: 'Số lượng', number: true),
                  _EditorField(controller: available, label: 'Còn sẵn', number: true),
                  _EditorField(controller: description, label: 'Mô tả', wide: true),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, Book(
                id: book?.id ?? 'book-${DateTime.now().microsecondsSinceEpoch}',
                title: title.text.trim(), author: author.text.trim(), category: category.text.trim(), publisher: publisher.text.trim(), isbn: isbn.text.trim(),
                year: int.tryParse(year.text) ?? 0, quantity: int.tryParse(quantity.text) ?? 0, available: int.tryParse(available.text) ?? 0, description: description.text.trim(),
              ));
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    try {
      final repository = ref.read(bookRepositoryProvider);
      if (book == null) {
        await repository.createBook(result);
      } else {
        await repository.updateBook(result);
      }
      ref.invalidate(bookListProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu sách.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _confirmDelete(BuildContext context, Book book) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sách?'),
        content: Text('Sách "${book.title}" sẽ bị xóa khỏi danh sách.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)), child: const Text('Xóa')),
        ],
      ),
    );
    if (approved != true) return;
    await ref.read(bookRepositoryProvider).deleteBook(book.id);
    ref.invalidate(bookListProvider);
  }

  void _showDetail(BuildContext context, Book book) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title),
        content: SizedBox(width: 460, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Info(label: 'Tác giả', value: book.author), _Info(label: 'Thể loại', value: book.category), _Info(label: 'Nhà xuất bản', value: book.publisher),
          _Info(label: 'ISBN', value: book.isbn), _Info(label: 'Năm xuất bản', value: '${book.year}'), _Info(label: 'Số lượng', value: '${book.available}/${book.quantity}'),
          const SizedBox(height: 8), Text(book.description),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE8ECF3))),
    );

class _EditorField extends StatelessWidget {
  const _EditorField({required this.controller, required this.label, this.required = false, this.number = false, this.wide = false});
  final TextEditingController controller;
  final String label;
  final bool required;
  final bool number;
  final bool wide;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: wide ? 596 : 292,
        child: TextFormField(
          controller: controller,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          validator: (value) => required && (value == null || value.trim().isEmpty) ? 'Bắt buộc' : null,
          decoration: _inputDecoration(label, Icons.edit_outlined),
        ),
      );
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.book});
  final Book book;
  @override
  Widget build(BuildContext context) {
    final available = book.available > 0;
    return Chip(label: Text(available ? 'Còn sách' : 'Hết sách'), backgroundColor: available ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2), labelStyle: TextStyle(color: available ? const Color(0xFF15803D) : const Color(0xFFDC2626), fontSize: 12));
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: RichText(text: TextSpan(style: DefaultTextStyle.of(context).style, children: [TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)), TextSpan(text: value)])));
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tải lại')));
}
