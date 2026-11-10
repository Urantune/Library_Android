import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/books/domain/entities/book.dart';
import 'package:lore_dungeo_library/features/books/presentation/providers/book_provider.dart';
import 'package:lore_dungeo_library/features/reservations/models/reservation.dart';
import 'package:lore_dungeo_library/features/reservations/providers/reservation_provider.dart';
import 'package:lore_dungeo_library/features/reservations/screens/reservation_list_screen.dart';

void main() {
  testWidgets('hiển thị lượt đang chờ và vị trí hàng đợi', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myReservationsProvider.overrideWith(
            (ref) async => const [
              Reservation(
                id: 'reservation-01',
                userId: 'user-01',
                bookId: 'book-01',
                status: 'WAITING',
                queuePosition: 2,
              ),
            ],
          ),
          bookDetailProvider('book-01').overrideWith(
            (ref) async => const Book(
              id: 'book-01',
              title: 'Nhà giả kim',
              author: 'Paulo Coelho',
              category: 'Văn học',
              publisher: 'NXB Hội Nhà Văn',
              isbn: '978-1',
              year: 1988,
              quantity: 1,
              available: 0,
            ),
          ),
        ],
        child: const MaterialApp(home: ReservationListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đặt trước sách'), findsOneWidget);
    expect(find.text('Nhà giả kim'), findsOneWidget);
    expect(find.text('Đang chờ'), findsOneWidget);
    expect(find.text('Vị trí 2'), findsOneWidget);
    expect(find.text('Hủy'), findsOneWidget);
  });

  testWidgets('hiển thị trạng thái trống thay cho trang đang phát triển',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myReservationsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: ReservationListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có lượt đặt trước nào'), findsOneWidget);
    expect(find.text('Trang này đang được phát triển'), findsNothing);
  });
}
