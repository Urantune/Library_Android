import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lore_dungeo_library/features/authors/domain/entities/author.dart';
import 'package:lore_dungeo_library/features/authors/presentation/providers/author_provider.dart';
import 'package:lore_dungeo_library/features/categories/models/book_category.dart';
import 'package:lore_dungeo_library/features/publishers/models/publisher.dart';
import 'package:lore_dungeo_library/features/books/domain/entities/book.dart';
import 'package:lore_dungeo_library/features/books/domain/repositories/book_repository.dart';
import 'package:lore_dungeo_library/features/books/presentation/providers/book_provider.dart';
import 'package:lore_dungeo_library/features/books/presentation/screens/book_add_screen.dart';

class MockBookRepository extends Mock implements BookRepository {}

void main() {
  const book = Book(id: '1', title: 'Title', author: 'Author', category: 'Category',
      publisher: 'Publisher', isbn: '9780132350884', year: 2024, quantity: 2,
      available: 1, authorIds: ['a'], categoryIds: ['c'], publisherId: 'p');
  late MockBookRepository repository;
  setUpAll(() => registerFallbackValue(book));
  setUp(() => repository = MockBookRepository());

  Future<void> open(WidgetTester tester, {Book? editing}) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [
      bookRepositoryProvider.overrideWithValue(repository),
      authorListProvider.overrideWith((ref) async => [const Author(id: 'a', name: 'Author', status: 'ACTIVE')]),
      bookCategoriesProvider.overrideWith((ref) async => [const BookCategory(id: 'c', name: 'Category')]),
      bookPublishersProvider.overrideWith((ref) async => [const Publisher(id: 'p', name: 'Publisher', address: '', phone: '', email: '')]),
    ], child: MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(onPressed: () => Navigator.push(context,
          MaterialPageRoute<void>(builder: (_) => BookAddScreen(book: editing))),
          child: const Text('Open')))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Lưu sách'));
    await tester.tap(find.text('Lưu sách'));
    await tester.pumpAndSettle();
  }

  testWidgets('validates required fields before calling repository', (tester) async {
    await open(tester);
    await save(tester);
    expect(find.text('Vui lòng nhập Tên sách'), findsOneWidget);
    verifyNever(() => repository.createBook(any()));
  });

  testWidgets('creates a book with selected relation IDs', (tester) async {
    when(() => repository.createBook(any())).thenAnswer((_) async {});
    await open(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Title');
    await tester.enterText(find.byType(TextFormField).at(1), '9780132350884');
    for (final name in ['Author', 'Category', 'Publisher']) {
      final index = ['Author', 'Category', 'Publisher'].indexOf(name);
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(index));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byType(TextFormField).at(2), '2024');
    await save(tester);
    final saved = verify(() => repository.createBook(captureAny())).captured.single as Book;
    expect(saved.authorIds, ['a']);
    expect(saved.categoryIds, ['c']);
    expect(saved.publisherId, 'p');
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('keeps the ID and displays persistence errors when editing', (tester) async {
    when(() => repository.updateBook(any())).thenThrow(StateError('Cannot save'));
    await open(tester, editing: book);
    await save(tester);
    expect(find.textContaining('Cannot save'), findsOneWidget);
    final edited = verify(() => repository.updateBook(captureAny())).captured.single as Book;
    expect(edited.id, '1');
    expect(edited.authorIds, ['a']);
  });
}
