import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/books/domain/entities/book.dart';
import 'package:lore_dungeo_library/features/books/domain/entities/book_page.dart';

Book book(String id, String title) => Book(
      id: id,
      title: title,
      author: 'Martin',
      category: 'Tech',
      publisher: 'NXB',
      isbn: 'isbn-$id',
      year: 2024,
      quantity: 2,
      available: 1,
    );

void main() {
  final books = [book('2', 'Beta'), book('1', 'Alpha'), book('3', 'Gamma')];

  test('sorts without mutating source and returns a page', () {
    final page = BookPage.fromBooks(books, size: 2);
    expect(page.items.map((b) => b.id), ['1', '2']);
    expect(page.totalElements, 3);
    expect(page.totalPages, 2);
    expect(books.first.id, '2');
  });

  test('searches title, author and ISBN case insensitively before paging', () {
    expect(BookPage.fromBooks(books, query: ' ALPHA ').totalElements, 1);
    expect(BookPage.fromBooks(books, query: 'martin').totalElements, 3);
    expect(BookPage.fromBooks(books, query: 'isbn-3').items.single.id, '3');
  });

  test('clamps a page when deletion reduces the total', () {
    final page = BookPage.fromBooks(books, page: 5, size: 2);
    expect(page.page, 1);
    expect(page.items.single.id, '3');
  });

  test('empty results have no pages and no items', () {
    final page = BookPage.fromBooks(books, query: 'missing');
    expect(page.page, 0);
    expect(page.totalPages, 0);
    expect(page.items, isEmpty);
  });

  test('rejects invalid page sizes and negative pages', () {
    expect(() => BookPage.fromBooks(books, size: 0), throwsArgumentError);
    expect(() => BookPage.fromBooks(books, size: 101), throwsArgumentError);
    expect(() => BookPage.fromBooks(books, page: -1), throwsArgumentError);
  });
}
