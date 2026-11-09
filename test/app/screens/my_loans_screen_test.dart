import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/app/screens/my_loans_screen.dart';

void main() {
  testWidgets('MyLoansScreen hiển thị sách đã mượn', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyLoansScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Sách đã mượn'), findsOneWidget);
    expect(find.text('Dế Mèn phiêu lưu ký'), findsOneWidget);
    expect(find.text('Clean Code'), findsOneWidget);
    expect(find.text('Tất cả (5)'), findsOneWidget);
  });

  testWidgets('MyLoansScreen lọc theo trạng thái quá hạn', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyLoansScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quá hạn (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Dế Mèn phiêu lưu ký'), findsOneWidget);
    expect(find.text('Clean Code'), findsNothing);
  });
}
