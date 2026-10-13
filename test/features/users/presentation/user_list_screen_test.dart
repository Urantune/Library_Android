import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/users/presentation/screens/user_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'users_data': '[]',
    });
  });

  testWidgets('UserListScreen displays title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Danh sách người dùng'), findsOneWidget);
  });

  testWidgets('UserListScreen shows loading indicator initially', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserListScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('UserListScreen displays users after loading', (tester) async {
    SharedPreferences.setMockInitialValues({
      'users_data': '''
      [
        {"id":"u1","username":"user1","email":"u1@test.com","fullName":"User One","role":"USER","status":"ACTIVE"},
        {"id":"u2","username":"user2","email":"u2@test.com","fullName":"User Two","role":"ADMIN","status":"LOCKED"}
      ]
      ''',
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('User One'), findsOneWidget);
    expect(find.text('User Two'), findsOneWidget);
  });

  testWidgets('UserListScreen filters by keyword', (tester) async {
    SharedPreferences.setMockInitialValues({
      'users_data': '''
      [
        {"id":"u1","username":"john","email":"john@test.com","fullName":"John Doe","role":"USER","status":"ACTIVE"},
        {"id":"u2","username":"jane","email":"jane@test.com","fullName":"Jane Smith","role":"USER","status":"ACTIVE"}
      ]
      ''',
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'john');
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Jane Smith'), findsNothing);
  });

  testWidgets('UserListScreen shows empty state when no users', (tester) async {
    SharedPreferences.setMockInitialValues({
      'users_data': '[]',
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có người dùng nào.'), findsOneWidget);
  });

  testWidgets('UserListScreen has add user FAB', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: UserListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Thêm người dùng'), findsOneWidget);
  });
}
