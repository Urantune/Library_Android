import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authors/domain/entities/author.dart';
import '../../../authors/presentation/providers/author_provider.dart';
import '../../../categories/models/book_category.dart';
import '../../../publishers/models/publisher.dart';
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
  late final TextEditingController _description;
  late final TextEditingController _language;
  late final TextEditingController _pageCount;
  late final TextEditingController _coverUrl;
  bool _saving = false;

  List<Author> _authors = [];
  List<BookCategory> _categories = [];
  List<Publisher> _publishers = [];
  String? _selectedAuthorId;
  String? _selectedCategoryId;
  String? _selectedPublisherId;
  bool _loadingRelations = true;
  bool _relationError = false;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _title = TextEditingController(text: book?.title);
    _author = TextEditingController(text: book?.author);
    _category = TextEditingController(text: book?.category);
    _publisher = TextEditingController(text: book?.publisher);
    _isbn = TextEditingController(text: book?.isbn);
    _year = TextEditingController(text: book?.year != null && book!.year > 0 ? book.year.toString() : '');
    _description = TextEditingController(text: book?.description);
    _language = TextEditingController(text: book?.language);
    _pageCount = TextEditingController(text: book?.pageCount?.toString());
    _coverUrl = TextEditingController(text: book?.coverUrl);
    _selectedPublisherId = book?.publisherId;
    if (book?.authorIds.isNotEmpty == true) {
      _selectedAuthorId = book!.authorIds.first;
    }
    if (book?.categoryIds.isNotEmpty == true) {
      _selectedCategoryId = book!.categoryIds.first;
    }
    _loadRelations();
  }

  Future<void> _loadRelations() async {
    setState(() { _loadingRelations = true; _relationError = false; });
    try {
      final results = await Future.wait([
        ref.refresh(authorListProvider.future),
        ref.refresh(bookCategoriesProvider.future),
        ref.refresh(bookPublishersProvider.future),
      ]);
      if (!mounted) return;
      setState(() {
        _authors = results[0] as List<Author>;
        _categories = results[1] as List<BookCategory>;
        _publishers = results[2] as List<Publisher>;

        if (_selectedAuthorId == null && widget.book?.author.isNotEmpty == true) {
          final found = _authors.where((a) => a.name.trim().toLowerCase() == widget.book!.author.trim().toLowerCase()).firstOrNull;
          if (found != null) _selectedAuthorId = found.id;
        }

        if (_selectedCategoryId == null && widget.book?.category.isNotEmpty == true) {
          final found = _categories.where((c) => c.name.trim().toLowerCase() == widget.book!.category.trim().toLowerCase()).firstOrNull;
          if (found != null) _selectedCategoryId = found.id;
        }

        if (_selectedPublisherId == null && widget.book?.publisher.isNotEmpty == true) {
          final found = _publishers.where((p) => p.name.trim().toLowerCase() == widget.book!.publisher.trim().toLowerCase()).firstOrNull;
          if (found != null) _selectedPublisherId = found.id;
        }

        _loadingRelations = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loadingRelations = false; _relationError = true; });
    }
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
      _description,
      _language,
      _pageCount,
      _coverUrl
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
                          _field(_isbn, 'ISBN', required: true),
                          _buildAuthorField(),
                          _buildCategoryField(),
                          _buildPublisherField(),
                          _field(_year, 'Năm xuất bản',
                              number: true, required: true),
                          _field(_language, 'Ngôn ngữ'),
                          _field(_pageCount, 'Số trang', number: true),
                          _field(_coverUrl, 'Đường dẫn ảnh bìa'),
                          _buildCopiesNotice(),
                          _field(_description, 'Mô tả', lines: 4),
                          if (_loadingRelations) const LinearProgressIndicator(),
                          if (_relationError)
                            TextButton(onPressed: _loadRelations, child: const Text('Không tải được dữ liệu liên quan. Thử lại')),
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

  Widget _buildCopiesNotice() {
    final qty = widget.book?.quantity ?? 0;
    final avail = widget.book?.available ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6E0EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF3157B7)),
              const SizedBox(width: 8),
              Text(
                'Bản sao lưu thông: $avail/$qty cuốn',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Số lượng bản sao vật lý được quản lý tự động qua hệ thống cá biệt (Book Copies / Mã vạch).',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorField() {
    if (_authors.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          initialValue: _authors.any((a) => a.id == _selectedAuthorId) ? _selectedAuthorId : null,
          decoration: InputDecoration(
            labelText: 'Tác giả',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: _authors
              .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedAuthorId = val;
              final found = _authors.where((a) => a.id == val).firstOrNull;
              if (found != null) _author.text = found.name;
            });
          },
          validator: (val) {
            if ((val == null || val.isEmpty) && _author.text.trim().isEmpty) {
              return 'Vui lòng chọn tác giả';
            }
            return null;
          },
        ),
      );
    }
    return _field(_author, 'Tác giả', required: true);
  }

  Widget _buildCategoryField() {
    if (_categories.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          initialValue: _categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null,
          decoration: InputDecoration(
            labelText: 'Thể loại',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: _categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedCategoryId = val;
              final found = _categories.where((c) => c.id == val).firstOrNull;
              if (found != null) _category.text = found.name;
            });
          },
          validator: (val) {
            if ((val == null || val.isEmpty) && _category.text.trim().isEmpty) {
              return 'Vui lòng chọn thể loại';
            }
            return null;
          },
        ),
      );
    }
    return _field(_category, 'Thể loại', required: true);
  }

  Widget _buildPublisherField() {
    if (_publishers.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          initialValue: _publishers.any((p) => p.id == _selectedPublisherId) ? _selectedPublisherId : null,
          decoration: InputDecoration(
            labelText: 'Nhà xuất bản',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: _publishers
              .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedPublisherId = val;
              final found = _publishers.where((p) => p.id == val).firstOrNull;
              if (found != null) _publisher.text = found.name;
            });
          },
          validator: (val) {
            if ((val == null || val.isEmpty) && _publisher.text.trim().isEmpty) {
              return 'Vui lòng chọn nhà xuất bản';
            }
            return null;
          },
        ),
      );
    }
    return _field(_publisher, 'Nhà xuất bản', required: true);
  }

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
            if (number && (required || (value?.trim().isNotEmpty ?? false)) && int.tryParse(value?.trim() ?? '') == null) {
              return 'Vui lòng nhập số nguyên';
            }
            final parsed = int.tryParse(value?.trim() ?? '');
            if (number && parsed != null && parsed < 0) {
              return 'Không được nhập số âm';
            }
            if (controller == _pageCount && parsed != null && parsed < 1) {
              return 'Số trang phải lớn hơn 0';
            }
            if (controller == _year &&
                parsed != null &&
                (parsed < 1 || parsed > DateTime.now().year + 1)) {
              return 'Năm xuất bản không hợp lệ';
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
    if (_loadingRelations || _relationError || _selectedAuthorId == null || _selectedCategoryId == null || _selectedPublisherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tải được hoặc chưa chọn tác giả, thể loại và nhà xuất bản.')));
      return;
    }
    setState(() => _saving = true);
    final authorName = _authors.where((a) => a.id == _selectedAuthorId).firstOrNull?.name ?? _author.text.trim();
    final categoryName = _categories.where((c) => c.id == _selectedCategoryId).firstOrNull?.name ?? _category.text.trim();
    final publisherName = _publishers.where((p) => p.id == _selectedPublisherId).firstOrNull?.name ?? _publisher.text.trim();

    final book = Book(
      id: widget.book?.id ?? 'book-${DateTime.now().microsecondsSinceEpoch}',
      title: _title.text.trim(),
      author: authorName,
      category: categoryName,
      publisher: publisherName,
      isbn: _isbn.text.trim(),
      year: int.tryParse(_year.text) ?? 0,
      quantity: widget.book?.quantity ?? 0,
      available: widget.book?.available ?? 0,
      description: _description.text.trim(),
      language: _language.text.trim(),
      pageCount: int.tryParse(_pageCount.text.trim()),
      coverUrl: _coverUrl.text.trim(),
      publisherId: _selectedPublisherId,
      authorIds: widget.book?.authorIds.firstOrNull == _selectedAuthorId ? widget.book!.authorIds : [_selectedAuthorId!],
      categoryIds: widget.book?.categoryIds.firstOrNull == _selectedCategoryId ? widget.book!.categoryIds : [_selectedCategoryId!],
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
      ref.invalidate(bookPagedProvider);
      ref.invalidate(bookListProvider);
      ref.invalidate(bookDetailProvider(book.id));
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error is StateError ? error.message : 'Không thể lưu sách. Vui lòng kiểm tra thông tin hoặc kết nối.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
