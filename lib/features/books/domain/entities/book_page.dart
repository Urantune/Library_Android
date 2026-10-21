import 'book.dart';

class BookPage {
  const BookPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<Book> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  factory BookPage.fromBooks(
    List<Book> books, {
    String query = '',
    int page = 0,
    int size = 10,
  }) {
    if (page < 0 || size < 1 || size > 100) {
      throw ArgumentError('Invalid page or size');
    }
    final keyword = query.trim().toLowerCase();
    final filtered = books.where((book) {
      return '${book.title} ${book.author} ${book.isbn}'
          .toLowerCase()
          .contains(keyword);
    }).toList()
      ..sort((a, b) {
        final title = a.title.compareTo(b.title);
        return title == 0 ? a.id.compareTo(b.id) : title;
      });
    final totalPages = (filtered.length / size).ceil();
    final currentPage = totalPages == 0 ? 0 : page.clamp(0, totalPages - 1);
    return BookPage(
      items: List.unmodifiable(filtered.skip(currentPage * size).take(size)),
      page: currentPage,
      size: size,
      totalElements: filtered.length,
      totalPages: totalPages,
    );
  }
}
