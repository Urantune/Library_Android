import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/app/screens/user_dashboard_home.dart';
import 'package:lore_dungeo_library/app/services/dashboard_service.dart';
import 'package:lore_dungeo_library/app/providers/dashboard_provider.dart';
import 'package:lore_dungeo_library/features/loans/data/models/loan_response.dart';
import 'package:lore_dungeo_library/features/loans/presentation/providers/loan_provider.dart';
import 'package:lore_dungeo_library/features/sign/controllers/auth_controller.dart';
import 'package:lore_dungeo_library/features/sign/models/user.dart' as auth;

const _user = auth.User(
  id: 'user-1',
  fullName: 'Test Reader',
  email: 'reader@example.com',
);

const _loanPage = PageDTO<LoanResponseDTO>(
  size: 20,
  page: 0,
  totalPages: 1,
  totalElements: 1,
  first: true,
  last: true,
  content: [
    LoanResponseDTO(
      id: 'loan-1',
      userId: 'user-1',
      status: 'BORROWED',
      renewCount: 0,
      items: [
        {
          'id': 'item-1',
          'bookId': 'book-1',
          'copyId': 'copy-1',
          'itemStatus': 'BORROWED',
          'conditionOnReturn': 'GOOD',
          'fineAmount': 0,
        },
      ],
    ),
  ],
);

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(user: _user);
}

void main() {
  Future<void> openDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
          booksOverviewProvider.overrideWith(
            (ref) async => const BooksOverview(total: 0, items: []),
          ),
          borrowedLoansProvider('user-1').overrideWith(
            (ref) async => _loanPage,
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: UserDashboardHome())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens a borrowed book item detail from the dashboard',
      (tester) async {
    await openDashboard(tester);

    final borrowedBook = find.text('Sách book-1');
    await tester.ensureVisible(borrowedBook);
    await tester.tap(borrowedBook);
    await tester.pumpAndSettle();

    expect(find.text('Mã mục mượn'), findsOneWidget);
    expect(find.text('Mã sách'), findsOneWidget);
    expect(find.text('book-1'), findsOneWidget);
    expect(find.text('Mã bản sao'), findsOneWidget);
    expect(find.text('copy-1'), findsOneWidget);
    expect(find.text('Trạng thái sách'), findsOneWidget);
    expect(find.text('Tình trạng khi trả'), findsOneWidget);
  });

  testWidgets('opens the user borrowed-loans screen from the dashboard',
      (tester) async {
    await openDashboard(tester);

    final viewLoans = find.text('Xem phiếu mượn');
    await tester.ensureVisible(viewLoans);
    await tester.tap(viewLoans);
    await tester.pumpAndSettle();

    expect(find.text('1 phiếu mượn'), findsOneWidget);
    expect(find.text('Sách đang mượn (1)'), findsOneWidget);
    expect(find.text('Không thể tải danh sách phiếu mượn'), findsNothing);
  });
}
