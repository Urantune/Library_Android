import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/app/library_app.dart';
import 'package:lore_dungeo_library/features/sign/controllers/auth_controller.dart';
import 'features/sign/fake_auth_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(FakeAuthService())],
        child: const LibraryApp()));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
