import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lore_dungeo_library/features/books/domain/entities/book.dart';
import 'package:lore_dungeo_library/features/books/domain/repositories/book_repository.dart';
import 'package:lore_dungeo_library/features/books/presentation/providers/book_provider.dart';
import 'package:lore_dungeo_library/features/books/presentation/screens/book_add_screen.dart';

class MockBookRepository extends Mock implements BookRepository {}

void main() {
  const book = Book(
      id: '1',
      title: 'Title',
      author: 'Author',
      category: 'Category',
      publisher: 'Publisher',
      isbn: '9780132350884',
      year: 2024,
      quantity: 2,
      available: 1);
  late MockBookRepository repository;

  setUpAll(() => registerFallbackValue(book));
  setUp(() => repository = MockBookRepository());

  Future<void> open(WidgetTester tester, {Book? editing}) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [bookRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => BookAddScreen(book: editing))),
                        child: const Text('Open')),
                  ))),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Lưu sách'));
    await tester.tap(find.text('Lưu sách'));
    await tester.pumpAndSettle();
  }

  testWidgets('validates required fields before calling repository',
      (tester) async {
    await open(tester);
    await save(tester);
    expect(find.text('Vui lòng nhập Tên sách'), findsOneWidget);
    verifyNever(() => repository.createBook(any()));
  });

  testWidgets('creates a valid fake book and closes after successful save',
      (tester) async {
    when(() => repository.createBook(any())).thenAnswer((_) async {});
    await open(tester);
    final values = [
      'Title',
      'Author',
      'Category',
      'Publisher',
      '9780132350884',
      '2024',
      '2',
      '1',
      'Description'
    ];
    for (var i = 0; i < values.length; i++) {
      await tester.ensureVisible(find.byType(TextFormField).at(i));
      await tester.enterText(find.byType(TextFormField).at(i), values[i]);
    }
    await save(tester);
    final saved = verify(() => repository.createBook(captureAny()))
        .captured
        .single as Book;
    expect(saved.title, 'Title');
    expect(saved.available, 1);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets(
      'keeps the existing ID when editing and displays persistence errors',
      (tester) async {
    when(() => repository.updateBook(any()))
        .thenThrow(StateError('Cannot save'));
    await open(tester, editing: book);
    await save(tester);
    expect(find.textContaining('Cannot save'), findsOneWidget);
    final edited = verify(() => repository.updateBook(captureAny()))
        .captured
        .single as Book;
    expect(edited.id, '1');
    expect(find.text('Cập nhật sách'), findsOneWidget);
  });

  testWidgets('does not save negative or excessive stock', (tester) async {
    await open(tester, editing: book);
    await tester.enterText(find.byType(TextFormField).at(7), '3');
    await save(tester);
    expect(find.text('Số còn sẵn không được vượt quá tổng số lượng'),
        findsOneWidget);
    verifyNever(() => repository.updateBook(any()));
  });
}
