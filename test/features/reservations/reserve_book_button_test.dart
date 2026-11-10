import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/app/screens/library_book_detail_screen.dart';
import 'package:lore_dungeo_library/features/books/domain/entities/book.dart';
import 'package:lore_dungeo_library/features/books/presentation/providers/book_provider.dart';
import 'package:lore_dungeo_library/features/reservations/models/reservation.dart';
import 'package:lore_dungeo_library/features/reservations/providers/reservation_provider.dart';
import 'package:lore_dungeo_library/features/reservations/services/reservation_service.dart';
import 'package:lore_dungeo_library/features/reservations/widgets/reserve_book_button.dart';
import 'package:mocktail/mocktail.dart';

/// Nguyen Duy Khang
/// Giả lập service để kiểm tra giao diện đặt trước độc lập với Backend.
class _MockReservationService extends Mock implements ReservationService {}

const _outOfStockBook = Book(
  id: 'book-01',
  title: 'Nhà giả kim',
  author: 'Paulo Coelho',
  category: 'Văn học',
  publisher: 'NXB Hội Nhà Văn',
  isbn: '978-1',
  year: 1988,
  quantity: 1,
  available: 0,
);

void main() {
  testWidgets('màn hình chi tiết hiện nút khi sách hết hàng', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookDetailProvider('book-01').overrideWith(
            (ref) async => _outOfStockBook,
          ),
        ],
        child: const MaterialApp(
          home: LibraryBookDetailScreen(bookId: 'book-01'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hết sách'), findsOneWidget);
    expect(find.text('Đặt trước sách'), findsOneWidget);
  });

  testWidgets('xác nhận và hiển thị vị trí hàng chờ khi đặt thành công',
      (tester) async {
    final service = _MockReservationService();
    when(() => service.createReservation('book-01')).thenAnswer(
      (_) async => const Reservation(
        id: 'reservation-01',
        userId: 'user-01',
        bookId: 'book-01',
        status: 'WAITING',
        queuePosition: 3,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [reservationServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(
          home: Scaffold(body: ReserveBookButton(book: _outOfStockBook)),
        ),
      ),
    );

    await tester.tap(find.text('Đặt trước sách'));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận đặt trước'), findsOneWidget);

    await tester.tap(find.text('Đặt trước'));
    await tester.pumpAndSettle();

    expect(find.text('Đặt trước thành công'), findsOneWidget);
    expect(find.textContaining('Vị trí hiện tại của bạn: 3'), findsOneWidget);
    verify(() => service.createReservation('book-01')).called(1);
  });

  testWidgets('không hiện nút khi sách còn bản khả dụng', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ReserveBookButton(
              book: Book(
                id: 'book-02',
                title: 'Clean Code',
                author: 'Robert C. Martin',
                category: 'Công nghệ',
                publisher: 'NXB Trẻ',
                isbn: '978-2',
                year: 2008,
                quantity: 2,
                available: 1,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Đặt trước sách'), findsNothing);
  });
}
