import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/books/data/datasources/book_local_data_source.dart';
import 'package:lore_dungeo_library/features/books/domain/entities/book.dart';

void main() {
  late Directory directory;
  late File file;
  const seed = Book(
      id: '1',
      title: 'Clean Code',
      author: 'Martin',
      category: 'Tech',
      publisher: 'NXB',
      isbn: '978-0132350884',
      year: 2008,
      quantity: 2,
      available: 1);

  BookLocalDataSource source() => BookLocalDataSource(
        fileResolver: () async => file,
        seedLoader: () async => jsonEncode([seed.toJson()]),
      );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('khang-books-test-');
    file = File('${directory.path}/urantune.json');
  });
  tearDown(() async => directory.delete(recursive: true));

  test('seeds once and persists create/update/delete across instances',
      () async {
    final data = source();
    expect((await data.getBooks()).length, 1);
    final added = Book(
        id: '2',
        title: 'Second',
        author: 'Author',
        category: 'Tech',
        publisher: 'NXB',
        isbn: '978-0000000001',
        year: 2024,
        quantity: 3,
        available: 2);
    await data.createBook(added);
    expect((await source().getBooks()).length, 2);
    await data.updateBook(added.copyWith(title: 'Changed'));
    expect((await source().getBookById('2')).title, 'Changed');
    await data.deleteBook('2');
    expect((await source().getBooks()).single.id, '1');
  });

  test('normalizes ISBN for create and update duplicate checks', () async {
    final data = source();
    final other = Book(
        id: '2',
        title: 'Other',
        author: 'A',
        category: 'C',
        publisher: 'P',
        isbn: '9780132350884',
        year: 2024,
        quantity: 1,
        available: 1);
    await expectLater(data.createBook(other), throwsStateError);
    await data.createBook(other.copyWith(isbn: '9780000000002'));
    await expectLater(data.updateBook(other), throwsStateError);
    expect((await data.getBookById('2')).isbn, '9780000000002');
  });

  test('allows updating a book without changing its own ISBN', () async {
    final data = source();
    await data.updateBook(seed.copyWith(title: 'Renamed'));
    expect((await data.getBookById('1')).title, 'Renamed');
  });

  test('rejects invalid quantities and missing books', () async {
    final data = source();
    await expectLater(
        data.updateBook(seed.copyWith(available: 3)), throwsStateError);
    await expectLater(
        data.updateBook(seed.copyWith(quantity: -1)), throwsStateError);
    await expectLater(data.getBookById('missing'), throwsStateError);
    await expectLater(data.deleteBook('missing'), throwsStateError);
  });

  test('does not hide corrupt JSON or overwrite it with seed', () async {
    await file.writeAsString('{invalid');
    await expectLater(source().getBooks(), throwsFormatException);
    expect(await file.readAsString(), '{invalid');
  });

  test('failed write leaves cache unchanged and later writes still work',
      () async {
    bool fail = false;
    final data = BookLocalDataSource(
      fileResolver: () async {
        if (fail) throw const FileSystemException('storage unavailable');
        return file;
      },
      seedLoader: () async => jsonEncode([seed.toJson()]),
    );
    await data.getBooks();
    fail = true;
    await expectLater(data.updateBook(seed.copyWith(title: 'Unsaved')),
        throwsA(isA<FileSystemException>()));
    expect((await data.getBookById('1')).title, 'Clean Code');
    fail = false;
    await data.updateBook(seed.copyWith(title: 'Saved'));
    expect((await source().getBookById('1')).title, 'Saved');
  });

  test('serializes concurrent edits instead of losing an update', () async {
    final data = source();
    await Future.wait([
      data.updateBook(seed.copyWith(title: 'First update')),
      data.updateBook(seed.copyWith(title: 'Last update')),
    ]);
    expect((await source().getBookById('1')).title, 'Last update');
  });
}
