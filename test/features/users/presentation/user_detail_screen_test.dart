import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/users/presentation/screens/user_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UserDetailScreen displays user info', (tester) async {
    SharedPreferences.setMockInitialValues({
      'users_data': '''
      [
        {"id":"u1","username":"john","email":"john@test.com","fullName":"John Doe","phone":"0123456789","role":"ADMIN","status":"ACTIVE"}
      ]
      ''',
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserDetailScreen(userId: 'u1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('@john'), findsOneWidget);
    expect(find.text('john@test.com'), findsOneWidget);
    expect(find.text('0123456789'), findsOneWidget);
  });

  testWidgets('UserDetailScreen shows edit and lock buttons', (tester) async {
    SharedPreferences.setMockInitialValues({
      'users_data': '''
      [
        {"id":"u1","username":"john","email":"john@test.com","fullName":"John Doe","role":"USER","status":"ACTIVE"}
      ]
      ''',
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserDetailScreen(userId: 'u1')),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down to make buttons visible
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Sửa'), findsOneWidget);
    expect(find.text('Khóa'), findsOneWidget);
    expect(find.text('Xóa người dùng'), findsOneWidget);
  });

  testWidgets('UserDetailScreen shows unlock button for locked user',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'users_data': '''
      [
        {"id":"u1","username":"john","email":"john@test.com","fullName":"John Doe","role":"USER","status":"LOCKED"}
      ]
      ''',
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserDetailScreen(userId: 'u1')),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down to make buttons visible
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Mở khóa'), findsOneWidget);
  });

  testWidgets('UserDetailScreen shows delete confirmation dialog',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'users_data': '''
      [
        {"id":"u1","username":"john","email":"john@test.com","fullName":"John Doe","role":"USER","status":"ACTIVE"}
      ]
      ''',
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserDetailScreen(userId: 'u1')),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down and tap delete button
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xóa người dùng'));
    await tester.pumpAndSettle();

    expect(find.text('Xóa người dùng'), findsWidgets);
    expect(find.text('Hủy'), findsOneWidget);
    expect(find.text('Xóa'), findsOneWidget);
  });

  testWidgets('UserDetailScreen shows lock confirmation dialog',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'users_data': '''
      [
        {"id":"u1","username":"john","email":"john@test.com","fullName":"John Doe","role":"USER","status":"ACTIVE"}
      ]
      ''',
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserDetailScreen(userId: 'u1')),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down and tap lock button
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Khóa'));
    await tester.pumpAndSettle();

    expect(find.text('Khóa người dùng'), findsOneWidget);
    expect(find.text('Hủy'), findsOneWidget);
  });
}
