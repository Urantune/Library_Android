import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/app/library_app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LibraryApp()));
    await tester.pumpAndSettle();

    expect(find.text('Thư viện số'), findsWidgets);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
