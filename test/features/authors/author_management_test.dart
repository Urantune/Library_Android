import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/authors/domain/entities/author.dart';
import 'package:lore_dungeo_library/features/authors/domain/repositories/author_repository.dart';
import 'package:lore_dungeo_library/features/authors/presentation/providers/author_provider.dart';
import 'package:lore_dungeo_library/features/authors/presentation/screens/author_add_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthorRepository extends Mock implements AuthorRepository {}

void main() {
  const author = Author(
    id: 'author-1',
    name: 'Author One',
    bio: 'Biography',
    country: 'VN',
    status: 'ACTIVE',
  );

  late _MockAuthorRepository repository;

  setUpAll(() => registerFallbackValue(author));
  setUp(() => repository = _MockAuthorRepository());

  Future<void> openForm(WidgetTester tester, {Author? editing}) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authorRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AuthorAddScreen(author: editing),
                  ),
                ),
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.widgetWithText(FilledButton, label));
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pumpAndSettle();
  }

  testWidgets('validates author name before calling repository',
      (tester) async {
    await openForm(tester);
    await save(tester, 'Lưu tác giả');

    expect(find.text('Vui lòng nhập tên tác giả.'), findsOneWidget);
    verifyNever(() => repository.createAuthor(any()));
  });

  testWidgets('creates author with entered fields', (tester) async {
    when(() => repository.createAuthor(any())).thenAnswer((_) async {});
    await openForm(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'New Author');
    await tester.enterText(find.byType(TextFormField).at(1), 'VN');
    await tester.enterText(find.byType(TextFormField).at(2), 'New biography');
    await save(tester, 'Lưu tác giả');

    final saved = verify(() => repository.createAuthor(captureAny()))
        .captured
        .single as Author;
    expect(saved.id, isEmpty);
    expect(saved.name, 'New Author');
    expect(saved.country, 'VN');
    expect(saved.bio, 'New biography');
    expect(saved.status, 'ACTIVE');
    expect(find.text('Open form'), findsOneWidget);
  });

  testWidgets('updates existing author while preserving its ID',
      (tester) async {
    when(() => repository.updateAuthor(any())).thenAnswer((_) async {});
    await openForm(tester, editing: author);

    await tester.enterText(find.byType(TextFormField).first, 'Updated Author');
    await save(tester, 'Cập nhật');

    final updated = verify(() => repository.updateAuthor(captureAny()))
        .captured
        .single as Author;
    expect(updated.id, 'author-1');
    expect(updated.name, 'Updated Author');
    expect(updated.country, 'VN');
    expect(find.text('Open form'), findsOneWidget);
  });
}