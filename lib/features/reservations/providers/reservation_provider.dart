import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/reservation_service.dart';

/// Cung cấp service để giao diện sử dụng và dễ thay bằng mock khi kiểm thử.
final reservationServiceProvider = Provider<ReservationService>(
  (ref) => ReservationService(),
);

/// Tải danh sách đặt trước của tài khoản hiện tại.
final myReservationsProvider = FutureProvider(
  (ref) => ref.watch(reservationServiceProvider).getMyReservations(),
);
