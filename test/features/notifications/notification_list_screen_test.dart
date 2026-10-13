import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/notifications/presentation/screens/notification_list_screen.dart';

void main() {
  testWidgets('NotificationListScreen displays title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsOneWidget);
  });

  testWidgets('NotificationListScreen shows notification items', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sách sắp đến hạn trả'), findsOneWidget);
    expect(find.text('Đặt trước thành công'), findsOneWidget);
    expect(find.text('Hệ thống bảo trì'), findsOneWidget);
    expect(find.text('Quá hạn trả sách'), findsOneWidget);
  });

  testWidgets('NotificationListScreen has "Đọc tất cả" button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đọc tất cả'), findsOneWidget);
  });

  testWidgets('NotificationListScreen shows notification types with icons',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('NotificationListScreen shows relative timestamps', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('giờ trước'), findsWidgets);
    expect(find.textContaining('ngày trước'), findsWidgets);
  });

  testWidgets('NotificationListScreen shows unread indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationListScreen()),
    );
    await tester.pumpAndSettle();

    // Unread notifications have a blue dot (Container with BoxShape.circle)
    final blueDots = find.byWidgetPredicate((widget) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).color == const Color(0xFF2563EB) &&
        (widget.decoration as BoxDecoration).shape == BoxShape.circle);
    expect(blueDots, findsWidgets);
  });
}
