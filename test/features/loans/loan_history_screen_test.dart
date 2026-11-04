import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/loans/presentation/screens/loan_history_screen.dart';

void main() {
  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoanHistoryScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows borrow, return, and renewal history', (tester) async {
    await openScreen(tester);

    expect(find.text('6 giao dịch'), findsOneWidget);
    expect(find.text('Dế Mèn phiêu lưu ký'), findsWidgets);
    expect(find.text('Nhà giả kim'), findsOneWidget);
    expect(find.text('Gia hạn thêm 14 ngày.'), findsWidgets);
  });

  testWidgets('filters loan history by book or member search', (tester) async {
    await openScreen(tester);

    await tester.enterText(find.byType(TextField), 'Clean Code');
    await tester.pumpAndSettle();

    expect(find.text('2 giao dịch'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'Clean Code',
      ),
      findsNWidgets(2),
    );
    expect(find.text('Dế Mèn phiêu lưu ký'), findsNothing);
  });

  testWidgets('filters history to returned books', (tester) async {
    await openScreen(tester);

    await tester.tap(find.text('Trả  2', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.text('2 giao dịch'), findsOneWidget);
    expect(find.text('Nhà giả kim'), findsOneWidget);
    expect(find.text('Đắc nhân tâm'), findsOneWidget);
    expect(find.text('Clean Code'), findsNothing);
  });

  testWidgets('shows an empty state when search has no matches',
      (tester) async {
    await openScreen(tester);

    await tester.enterText(find.byType(TextField), 'no matching record');
    await tester.pumpAndSettle();

    expect(find.text('0 giao dịch'), findsOneWidget);
    expect(find.text('Không tìm thấy giao dịch'), findsOneWidget);
  });
}