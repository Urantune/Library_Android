import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/books/domain/entities/book.dart';

void main() {
  test('Book serializes and deserializes', () {
    const book = Book(
      id: 'book-001',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'Công nghệ',
      publisher: 'O Reilly',
      isbn: '9780132350884',
      year: 2019,
      quantity: 6,
      available: 2,
    );

    expect(Book.fromJson(book.toJson()).title, book.title);
    expect(book.copyWith(available: 1).available, 1);
  });
}
