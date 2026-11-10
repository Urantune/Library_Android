import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../sign/controllers/auth_controller.dart';
import '../../data/notification_api.dart';

final notificationApiProvider = Provider<NotificationApi>((ref) => NotificationApi());
final unreadNotificationCountProvider = FutureProvider<int>((ref) {
  final userId = ref.watch(authControllerProvider.select((state) => state.user?.id));
  if (userId == null || userId.isEmpty) return Future.value(0);
  final timer = Timer(const Duration(seconds: 30), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return ref.watch(notificationApiProvider).unreadCount();
});
