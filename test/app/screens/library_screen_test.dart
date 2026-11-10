import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/app/screens/library_book_detail_screen.dart';
import 'package:lore_dungeo_library/app/screens/library_screen.dart';
import 'package:lore_dungeo_library/features/books/domain/entities/book.dart';
import 'package:lore_dungeo_library/features/books/domain/entities/book_page.dart';
import 'package:lore_dungeo_library/features/books/presentation/providers/book_provider.dart';

const _books = [
  Book(
    id: '1',
    title: 'Clean Code',
    author: 'Robert C. Martin',
    category: 'Công nghệ',
    publisher: 'NXB Trẻ',
    isbn: '978-0',
    year: 2008,
    quantity: 3,
    available: 2,
  ),
  Book(
    id: '2',
    title: 'Nhà giả kim',
    author: 'Paulo Coelho',
    category: 'Văn học',
    publisher: 'NXB Hội Nhà Văn',
    isbn: '978-1',
    year: 1988,
    quantity: 1,
    available: 0,
  ),
];

Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        bookPagedProvider.overrideWith((ref, query) async => BookPage.fromBooks(
          query.copyStatus == 'AVAILABLE' ? _books.where((book) => book.available > 0).toList() : _books,
          query: query.query, page: query.page, size: query.size)),
        bookDetailProvider.overrideWith((ref, id) async {
          return _books.firstWhere((book) => book.id == id);
        }),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('LibraryScreen hiển thị sách và trạng thái còn/hết', (tester) async {
    await tester.pumpWidget(_wrap(const LibraryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Thư viện'), findsOneWidget);
    expect(find.text('Clean Code'), findsOneWidget);
    expect(find.text('Còn 2 cuốn'), findsOneWidget);
    expect(find.text('Hết sách'), findsOneWidget);
    expect(find.text('2 sách'), findsOneWidget);
  });

  testWidgets('LibraryScreen tìm kiếm theo tên sách', (tester) async {
    await tester.pumpWidget(_wrap(const LibraryScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'nhà giả kim');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Nhà giả kim'), findsOneWidget);
    expect(find.text('Clean Code'), findsNothing);
  });

  testWidgets('Bấm sách mở chi tiết chỉ đọc', (tester) async {
    await tester.pumpWidget(_wrap(const LibraryScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clean Code'));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryBookDetailScreen), findsOneWidget);
    expect(find.text('Thông tin sách'), findsOneWidget);
    // Không có nút quản trị.
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });
}
