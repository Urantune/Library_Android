import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/books/domain/entities/book.dart';
import 'package:lore_dungeo_library/features/books/presentation/providers/book_provider.dart';
import 'package:lore_dungeo_library/features/books/presentation/screens/book_list_screen.dart';

void main() {
  final books = List.generate(
      12,
      (i) => Book(
            id: '$i',
            title: 'Book ${i.toString().padLeft(2, '0')}',
            author: 'Author',
            category: 'Technology',
            publisher: 'NXB',
            isbn: 'isbn-$i',
            year: 2024,
            quantity: 2,
            available: 1,
          ));

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        bookListProvider.overrideWith((ref) async => books),
        bookDetailProvider('0').overrideWith((ref) async => books.first),
      ],
      child: const MaterialApp(home: BookListScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('moves between pages and resets page after search',
      (tester) async {
    await open(tester);
    expect(find.text('12 sách · Trang 1/2'), findsOneWidget);
    await tester.tap(find.byTooltip('Trang sau'));
    await tester.pumpAndSettle();
    expect(find.text('12 sách · Trang 2/2'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Book 00');
    await tester.pumpAndSettle();
    expect(find.text('1 sách · Trang 1/1'), findsOneWidget);
    expect(find.text('Book 00'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows empty search state', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'not-in-fixture');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy sách phù hợp.'), findsOneWidget);
  });

  testWidgets('opens book detail using the selected ID', (tester) async {
    await open(tester);
    await tester.tap(find.text('Book 00').first);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết sách'), findsOneWidget);
    expect(find.text('Thông tin sách'), findsOneWidget);
    expect(find.text('Book 00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
