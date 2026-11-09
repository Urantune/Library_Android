import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/app/widgets/sidebar.dart';

Widget _wrap({required bool isStaff}) => MaterialApp(
      home: Scaffold(
        body: Sidebar(
          selectedIndex: 0,
          onSelected: (_) {},
          onClose: () {},
          isStaff: isStaff,
        ),
      ),
    );

void main() {
  testWidgets('Sidebar độc giả chỉ hiện mục dành cho bạn đọc', (tester) async {
    await tester.pumpWidget(_wrap(isStaff: false));

    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Thư viện'), findsOneWidget);
    expect(find.text('Sách đã mượn'), findsOneWidget);
    expect(find.text('Đặt trước'), findsOneWidget);
    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);

    // Không còn mục vận hành/quản trị.
    expect(find.text('Tác giả'), findsNothing);
    expect(find.text('Thể loại'), findsNothing);
    expect(find.text('Nhà xuất bản'), findsNothing);
    expect(find.text('Người dùng'), findsNothing);
    expect(find.text('Báo cáo'), findsNothing);
    expect(find.text('Quản trị hệ thống'), findsNothing);
  });

  testWidgets('Sidebar quản trị/thủ thư giữ đầy đủ mục', (tester) async {
    await tester.pumpWidget(_wrap(isStaff: true));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Sách'), findsOneWidget);
    expect(find.text('Tác giả'), findsOneWidget);
    expect(find.text('Thể loại'), findsOneWidget);
    expect(find.text('Nhà xuất bản'), findsOneWidget);
    expect(find.text('Người dùng'), findsOneWidget);
    expect(find.text('Mượn - Trả'), findsOneWidget);
    expect(find.text('Báo cáo'), findsOneWidget);
    expect(find.text('Quản trị hệ thống'), findsOneWidget);
  });
}
