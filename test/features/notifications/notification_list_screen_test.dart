import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/notifications/data/notification_api.dart';
import 'package:lore_dungeo_library/features/notifications/presentation/providers/notification_provider.dart';
import 'package:lore_dungeo_library/features/notifications/presentation/screens/notification_list_screen.dart';

class FakeNotificationApi extends NotificationApi {
  bool read = false;
  @override
  Future<NotificationPage> list({required int page, required bool unreadOnly}) async => NotificationPage(
    unreadOnly && read ? [] : [AppNotification(id: '1', title: 'Thông báo thật', body: 'Nội dung', isRead: read, createdAt: null)], 1);
  @override
  Future<void> markRead(String id) async { read = true; }
  @override
  Future<void> markAllRead() async { read = true; }
  @override
  Future<int> unreadCount() async => read ? 0 : 1;
}

void main() {
  testWidgets('loads notifications, marks read and filters unread', (tester) async {
    final api = FakeNotificationApi();
    await tester.pumpWidget(ProviderScope(overrides: [notificationApiProvider.overrideWithValue(api)], child: const MaterialApp(home: NotificationListScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Thông báo thật'), findsOneWidget);
    await tester.tap(find.text('Thông báo thật'));
    await tester.pumpAndSettle();
    expect(api.read, isTrue);
    await tester.tap(find.text('Chưa đọc'));
    await tester.pumpAndSettle();
    expect(find.text('Không có thông báo chưa đọc.'), findsOneWidget);
  });
}
