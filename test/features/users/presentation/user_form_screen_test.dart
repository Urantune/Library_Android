import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/users/domain/entities/user.dart';
import 'package:lore_dungeo_library/features/users/presentation/screens/user_form_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'users_data': '[]',
    });
  });

  testWidgets('UserFormScreen shows add mode title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // AppBar title
    expect(find.widgetWithText(AppBar, 'Thêm người dùng'), findsOneWidget);
  });

  testWidgets('UserFormScreen shows edit mode title when user provided',
      (tester) async {
    final user = User(
      id: 'u1',
      username: 'john',
      email: 'john@test.com',
      fullName: 'John Doe',
      role: 'USER',
      status: 'ACTIVE',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: UserFormScreen(user: user)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Sửa người dùng'), findsOneWidget);
  });

  testWidgets('UserFormScreen validates required fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the submit button
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm người dùng'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    expect(find.text('Vui lòng nhập tên đăng nhập'), findsOneWidget);
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
  });

  testWidgets('UserFormScreen validates email format', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Họ và tên *'), 'Test User');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên đăng nhập *'), 'testuser');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email *'), 'invalid-email');

    await tester.tap(find.widgetWithText(FilledButton, 'Thêm người dùng'));
    await tester.pumpAndSettle();

    expect(find.text('Email không hợp lệ'), findsOneWidget);
  });

  testWidgets('UserFormScreen validates username min length', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Họ và tên *'), 'Test User');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên đăng nhập *'), 'ab');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email *'), 'test@test.com');

    await tester.tap(find.widgetWithText(FilledButton, 'Thêm người dùng'));
    await tester.pumpAndSettle();

    expect(find.text('Tên đăng nhập ít nhất 3 ký tự'), findsOneWidget);
  });
}
