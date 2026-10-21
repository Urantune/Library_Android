import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/books/data/dto/book_dto.dart';

void main() {
  test('maps the server book DTO without changing the fixture format', () {
    final book = const BookDto({
      'id': 'book-1',
      'title': 'Clean Code',
      'isbn': '9780132350884',
      'authors': [
        {'id': 'a1', 'name': 'Robert Martin'}
      ],
      'categories': [
        {'id': 'c1', 'name': 'Technology'}
      ],
      'publisher': {'id': 'p1', 'name': 'NXB'},
      'publicationYear': 2008,
      'totalCopies': 2,
      'availableCopies': 1,
      'description': 'Description',
    }).toDomain();
    expect(book.id, 'book-1');
    expect(book.author, 'Robert Martin');
    expect(book.category, 'Technology');
    expect(book.publisher, 'NXB');
    expect(book.year, 2008);
    expect(book.quantity, 2);
    expect(book.available, 1);
  });

  test('handles nullable relationships and optional values', () {
    final book = const BookDto({'id': '1', 'title': 'Book'}).toDomain();
    expect(book.author, '');
    expect(book.category, '');
    expect(book.publisher, '');
    expect(book.year, 0);
  });
}
