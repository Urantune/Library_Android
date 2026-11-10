import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/books/domain/entities/book.dart';
import 'package:lore_dungeo_library/features/loans/data/datasources/loan_remote_data_source.dart';
import 'package:lore_dungeo_library/features/loans/data/models/loan_renewal_response.dart';
import 'package:lore_dungeo_library/features/loans/data/models/loan_response.dart';
import 'package:lore_dungeo_library/features/loans/presentation/providers/loan_provider.dart';
import 'package:lore_dungeo_library/features/loans/presentation/screens/borrowed_loans_screen.dart';
import 'package:lore_dungeo_library/features/sign/controllers/auth_controller.dart';
import 'package:lore_dungeo_library/features/sign/models/user.dart' as auth;
import 'package:lore_dungeo_library/features/users/domain/entities/user.dart';

const _authUser = auth.User(
    id: 'user-1', fullName: 'Test Reader', email: 'reader@example.com');
const _staffAuthUser = auth.User(
  id: 'staff-1',
  fullName: 'Test Staff',
  email: 'staff@example.com',
  roles: ['ADMIN'],
);

const _user = User(
  id: 'user-1',
  username: 'reader',
  email: 'reader@example.com',
  fullName: 'Test Reader',
  role: 'USER',
  status: 'ACTIVE',
);

final _loans = PageDTO<LoanResponseDTO>(
  size: 20,
  page: 0,
  totalPages: 1,
  totalElements: 2,
  first: true,
  last: true,
  content: [
    LoanResponseDTO(
      id: 'loan-1',
      userId: 'user-1',
      status: 'BORROWED',
      requestedAt: null,
      borrowedAt: null,
      dueAt: DateTime(2099, 12, 31),
      renewCount: 1,
      items: [
        {
          'id': 'item-1',
          'bookId': 'book-1',
          'copyId': 'copy-1',
          'itemStatus': 'BORROWED',
          'returnedAt': '2026-11-01T10:00:00',
          'conditionOnReturn': 'GOOD',
          'fineAmount': 0,
        },
        {'bookId': 'book-2'},
      ],
    ),
    LoanResponseDTO(
      id: 'loan-2',
      userId: 'user-1',
      status: 'REQUESTED',
      renewCount: 0,
      items: [
        {'bookId': 'book-3'},
      ],
    ),
  ],
);

class _FakeLoanRemoteDataSource implements LoanRemoteDataSource {
  String? requestedUserId;
  List<Map<String, dynamic>>? requestedItems;
  DateTime? requestedDueAt;
  String? renewedLoanId;
  String? renewalReason;
  String? approvedRenewalId;
  var getAllLoansCallCount = 0;
  var getBorrowedLoansCallCount = 0;

  static const pendingRenewal = LoanRenewalResponseDTO(
    id: 'renewal-1',
    loanId: 'loan-1',
    requestedBy: 'user-1',
    requestedAt: null,
    previousDueAt: null,
    newDueAt: null,
    status: 'REQUESTED',
    reason: 'Travel',
  );

  @override
  String get baseUrl => 'http://localhost:8083';

  @override
  Future<PageDTO<LoanResponseDTO>> getBorrowedLoans(
    String userId, {
    int page = 0,
    int size = 20,
  }) async {
    getBorrowedLoansCallCount++;
    return _loans;
  }

  @override
  Future<LoanResponseDTO> requestLoan({
    required String userId,
    required List<Map<String, dynamic>> items,
    required DateTime dueAt,
    CancelToken? cancelToken,
  }) async {
    requestedUserId = userId;
    requestedItems = items;
    requestedDueAt = dueAt;
    return const LoanResponseDTO(
      id: 'loan-new',
      userId: 'user-1',
      status: 'REQUESTED',
      renewCount: 0,
      items: [
        {'bookId': 'book-1'},
      ],
    );
  }

  @override
  Future<LoanResponseDTO> approveLoan(
      {required String loanId,
      required String adminUserId,
      required String userRoles}) {
    // TODO: implement approveLoan
    throw UnimplementedError();
  }

  @override
  Future<LoanRenewalResponseDTO> requestRenewal({
    required String userId,
    required String loanId,
    String? reason,
  }) async {
    renewedLoanId = loanId;
    renewalReason = reason;
    return LoanRenewalResponseDTO(
      id: 'renewal-1',
      loanId: loanId,
      requestedBy: userId,
      status: 'REQUESTED',
      reason: reason,
    );
  }

  @override
  Future<List<LoanRenewalResponseDTO>> getRenewals() async => [pendingRenewal];

  @override
  Future<LoanRenewalResponseDTO> approveRenewal({
    required String renewalId,
    required String adminUserId,
  }) async {
    approvedRenewalId = renewalId;
    return LoanRenewalResponseDTO(
      id: renewalId,
      loanId: 'loan-1',
      requestedBy: 'user-1',
      status: 'APPROVED',
      approvedBy: adminUserId,
    );
  }

  @override
  Future<PageDTO<LoanResponseDTO>> getAllLoans(
      {String? userRoles, int page = 0, int size = 20}) {
    getAllLoansCallCount++;
    return Future.value(_loans);
  }

  @override
  Future<LoanResponseDTO> rejectLoan(
      {required String loanId,
      required String adminUserId,
      required String userRoles,
      String? reason}) {
    // TODO: implement rejectLoan
    throw UnimplementedError();
  }
}

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(user: _staffAuthUser);

  void switchUser(auth.User user) {
    state = AuthState(user: user);
  }
}

class _SwitchableMemberAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(user: _authUser);

  void setUser(auth.User? user) {
    state = AuthState(user: user);
  }
}

void main() {
  test('reloads admin loans when the authenticated user changes', () async {
    final remoteDataSource = _FakeLoanRemoteDataSource();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_TestAuthController.new),
        loanRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      adminLoansProvider('ADMIN'),
      (_, __) {},
    );
    addTearDown(subscription.close);

    await container.read(adminLoansProvider('ADMIN').future);
    expect(remoteDataSource.getAllLoansCallCount, 1);

    (container.read(authControllerProvider.notifier) as _TestAuthController)
        .switchUser(
      const auth.User(
        id: 'staff-2',
        fullName: 'Another Staff',
        email: 'staff2@example.com',
        roles: ['ADMIN'],
      ),
    );
    await container.read(adminLoansProvider('ADMIN').future);

    expect(remoteDataSource.getAllLoansCallCount, 2);
  });

  test('reloads borrowed loans when the user logs out and back in', () async {
    final remoteDataSource = _FakeLoanRemoteDataSource();
    final container = ProviderContainer(
      overrides: [
        authControllerProvider
            .overrideWith(_SwitchableMemberAuthController.new),
        loanRemoteDataSourceProvider.overrideWithValue(remoteDataSource),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      borrowedLoansProvider('user-1'),
      (_, __) {},
    );
    addTearDown(subscription.close);

    await container.read(borrowedLoansProvider('user-1').future);
    expect(remoteDataSource.getBorrowedLoansCallCount, 1);

    (container.read(authControllerProvider.notifier)
            as _SwitchableMemberAuthController)
        .setUser(null);
    await expectLater(
      container.read(borrowedLoansProvider('user-1').future),
      throwsA(isA<StateError>()),
    );

    (container.read(authControllerProvider.notifier)
            as _SwitchableMemberAuthController)
        .setUser(_authUser);
    await container.read(borrowedLoansProvider('user-1').future);

    expect(remoteDataSource.getBorrowedLoansCallCount, 2);
  });

  Future<void> openScreen(
    WidgetTester tester, {
    List<Book> books = const [],
    _FakeLoanRemoteDataSource? remoteDataSource,
    auth.User currentUser = _authUser,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loanCurrentUserIdProvider.overrideWith((ref) async => _user.id),
          loanCurrentUserInfoProvider.overrideWithValue(currentUser),
          borrowedLoansProvider('user-1').overrideWith((ref) async => _loans),
          adminLoansProvider('ADMIN').overrideWith((ref) async => _loans),
          adminLoanRenewalsProvider.overrideWith(
            (ref) async => [_FakeLoanRemoteDataSource.pendingRenewal],
          ),
          loanBookListProvider.overrideWith((ref) async => books),
          loanRemoteDataSourceProvider.overrideWithValue(
            remoteDataSource ?? _FakeLoanRemoteDataSource(),
          ),
        ],
        child: const MaterialApp(home: BorrowedLoansScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('displays borrowed loan data from the provider', (tester) async {
    await openScreen(tester);

    expect(find.text('2 phiếu mượn'), findsOneWidget);
    expect(find.text('Phiếu loan-1'), findsWidgets);
    expect(find.text('BORROWED'), findsOneWidget);
    expect(find.text('2 đầu sách  ·  Đã gia hạn 1 lần'), findsOneWidget);
    expect(find.text('Sách mã book-1'), findsWidgets);
  });

  testWidgets('hides the request-loan action for staff', (tester) async {
    await openScreen(tester, currentUser: _staffAuthUser);

    expect(find.text('Yêu cầu mượn sách'), findsNothing);
    expect(find.text('Duyệt'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);
  });

  testWidgets('admin sees pending renewal and can approve it', (tester) async {
    final remoteDataSource = _FakeLoanRemoteDataSource();
    await openScreen(
      tester,
      currentUser: _staffAuthUser,
      remoteDataSource: remoteDataSource,
    );

    expect(find.text('Yêu cầu gia hạn chờ duyệt'), findsOneWidget);
    expect(find.text('Phiếu loan-1'), findsWidgets);
    expect(find.text('Lý do'), findsOneWidget);

    final approveButton = find.text('Duyệt gia hạn');
    await tester.ensureVisible(approveButton);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(approveButton);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Xác nhận duyệt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(remoteDataSource.approvedRenewalId, 'renewal-1');
    expect(find.text('Đã duyệt gia hạn phiếu loan-1.'), findsOneWidget);
  });

  testWidgets('filters borrowed loans by ID or status', (tester) async {
    await openScreen(tester);

    await tester.enterText(find.byType(TextField), 'requested');
    await tester.pumpAndSettle();

    expect(find.text('Phiếu loan-2'), findsOneWidget);
    expect(find.text('Phiếu loan-1'), findsNothing);
  });

  testWidgets('shows loan item details when a borrowed book is tapped',
      (tester) async {
    await openScreen(tester);

    await tester.tap(find.text('Sách mã book-1').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Mã mục: item-1'), findsOneWidget);
    expect(find.textContaining('Bản sao: copy-1'), findsOneWidget);
    expect(find.textContaining('Tình trạng khi trả: GOOD'), findsOneWidget);
    expect(find.textContaining('Tiền phạt: 0'), findsOneWidget);
  });

  testWidgets('submits a renewal request for a borrowed loan', (tester) async {
    final remoteDataSource = _FakeLoanRemoteDataSource();
    await openScreen(tester, remoteDataSource: remoteDataSource);

    final renewButton = find.text('Yêu cầu gia hạn');
    await tester.ensureVisible(renewButton);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(renewButton);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Thời gian gia hạn: 7 ngày'), findsOneWidget);
    expect(
      find.text('Hạn mới dự kiến nếu được duyệt: 07/01/2100'),
      findsOneWidget,
    );
    expect(find.text('Gửi yêu cầu'), findsOneWidget);
    await tester.tap(find.text('Gửi yêu cầu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(remoteDataSource.renewedLoanId, 'loan-1');
    expect(remoteDataSource.renewalReason, isEmpty);
    expect(find.text('Đang chờ duyệt gia hạn'), findsOneWidget);
    expect(
      find.textContaining('Đã gửi yêu cầu gia hạn phiếu loan-1'),
      findsOneWidget,
    );
  });

  testWidgets('shows an empty state when search has no matches',
      (tester) async {
    await openScreen(tester);

    await tester.enterText(find.byType(TextField), 'missing-loan');
    await tester.pumpAndSettle();

    expect(find.text('2 phiếu mượn'), findsOneWidget);
    expect(find.text('Không có phiếu mượn phù hợp.'), findsOneWidget);
  });

  testWidgets('sends a loan request for selected available books',
      (tester) async {
    final remoteDataSource = _FakeLoanRemoteDataSource();
    const book = Book(
      id: 'book-1',
      title: 'Book One',
      author: 'Author',
      category: 'Category',
      publisher: 'Publisher',
      isbn: '123',
      year: 2024,
      quantity: 2,
      available: 1,
    );
    await openScreen(
      tester,
      books: const [book],
      remoteDataSource: remoteDataSource,
    );

    await tester.tap(find.text('Yêu cầu mượn sách'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hạn trả dự kiến'), findsOneWidget);
    await tester.tap(find.text('Hạn trả dự kiến'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(
      find
          .descendant(
            of: find.byType(DatePickerDialog),
            matching: find.byType(TextButton),
          )
          .first,
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Book One'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Gửi yêu cầu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(remoteDataSource.requestedUserId, 'user-1');
    expect(remoteDataSource.requestedItems, [
      {'bookId': 'book-1'},
    ]);
    expect(
      remoteDataSource.requestedDueAt,
      DateUtils.dateOnly(DateTime.now().add(const Duration(days: 7))),
    );
    expect(
      find.text('Đã gửi phiếu loan-new với 1 đầu sách.'),
      findsOneWidget,
    );
  });

  testWidgets('allows selecting active books when available count is zero',
      (tester) async {
    const book = Book(
      id: 'book-empty',
      title: 'No Copies Book',
      author: 'Author',
      category: 'Category',
      publisher: 'Publisher',
      isbn: '456',
      year: 2024,
      quantity: 0,
      available: 0,
      status: 'ACTIVE',
    );
    await openScreen(tester, books: const [book]);

    await tester.tap(find.text('Yêu cầu mượn sách'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No Copies Book'), findsOneWidget);
    expect(find.text('ACTIVE · Còn 0 bản'), findsOneWidget);
    await tester.tap(find.text('No Copies Book'));
    await tester.pump();
    final requestButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Gửi yêu cầu'),
    );
    expect(requestButton.onPressed, isNotNull);
  });
}
