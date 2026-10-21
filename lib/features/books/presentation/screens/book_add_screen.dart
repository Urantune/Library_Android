import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/book.dart';
import '../../domain/entities/book_validation.dart';
import '../providers/book_provider.dart';

class BookAddScreen extends ConsumerStatefulWidget {
  const BookAddScreen({super.key, this.book});
  final Book? book;

  @override
  ConsumerState<BookAddScreen> createState() => _BookAddScreenState();
}

class _BookAddScreenState extends ConsumerState<BookAddScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _category;
  late final TextEditingController _publisher;
  late final TextEditingController _isbn;
  late final TextEditingController _year;
  late final TextEditingController _quantity;
  late final TextEditingController _available;
  late final TextEditingController _description;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _title = TextEditingController(text: book?.title);
    _author = TextEditingController(text: book?.author);
    _category = TextEditingController(text: book?.category);
    _publisher = TextEditingController(text: book?.publisher);
    _isbn = TextEditingController(text: book?.isbn);
    _year = TextEditingController(text: book?.year.toString());
    _quantity = TextEditingController(text: book?.quantity.toString());
    _available = TextEditingController(text: book?.available.toString());
    _description = TextEditingController(text: book?.description);
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _author,
      _category,
      _publisher,
      _isbn,
      _year,
      _quantity,
      _available,
      _description
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
            title: Text(widget.book == null ? 'Thêm sách' : 'Cập nhật sách'),
            backgroundColor: Colors.white),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE6EAF0))),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _field(_title, 'Tên sách', required: true),
                          _field(_author, 'Tác giả', required: true),
                          _field(_category, 'Thể loại', required: true),
                          _field(_publisher, 'Nhà xuất bản', required: true),
                          _field(_isbn, 'ISBN', required: true),
                          _field(_year, 'Năm xuất bản',
                              number: true, required: true),
                          _field(_quantity, 'Số lượng',
                              number: true, required: true),
                          _field(_available, 'Số lượng còn sẵn',
                              number: true, required: true),
                          _field(_description, 'Mô tả', lines: 4),
                          const SizedBox(height: 12),
                          FilledButton(
                              onPressed: _saving ? null : _save,
                              child:
                                  Text(_saving ? 'Đang lưu...' : 'Lưu sách')),
                        ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _field(TextEditingController controller, String label,
          {bool required = false, bool number = false, int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          maxLines: lines,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'Vui lòng nhập $label';
            }
            if (number && int.tryParse(value?.trim() ?? '') == null) {
              return 'Vui lòng nhập số nguyên';
            }
            final parsed = int.tryParse(value?.trim() ?? '');
            if (number && parsed != null && parsed < 0) {
              return 'Không được nhập số âm';
            }
            if (controller == _year &&
                parsed != null &&
                (parsed < 1 || parsed > DateTime.now().year + 1)) {
              return 'Năm xuất bản không hợp lệ';
            }
            if (controller == _available &&
                parsed != null &&
                parsed > (int.tryParse(_quantity.text.trim()) ?? 0)) {
              return 'Số còn sẵn không được vượt quá tổng số lượng';
            }
            return null;
          },
          decoration: InputDecoration(
              labelText: label,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        ),
      );

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final book = Book(
      id: widget.book?.id ?? 'book-${DateTime.now().microsecondsSinceEpoch}',
      title: _title.text.trim(),
      author: _author.text.trim(),
      category: _category.text.trim(),
      publisher: _publisher.text.trim(),
      isbn: _isbn.text.trim(),
      year: int.tryParse(_year.text) ?? 0,
      quantity: int.tryParse(_quantity.text) ?? 0,
      available: int.tryParse(_available.text) ?? 0,
      description: _description.text.trim(),
    );
    try {
      final errors = BookValidation.validate(book);
      if (errors.isNotEmpty) throw StateError(errors.values.first);
      final repository = ref.read(bookRepositoryProvider);
      if (widget.book == null) {
        await repository.createBook(book);
      } else {
        await repository.updateBook(book);
      }
      ref.invalidate(bookListProvider);
      ref.invalidate(bookDetailProvider(book.id));
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
