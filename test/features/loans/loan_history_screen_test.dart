import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/books/domain/entities/book.dart';
import 'package:lore_dungeo_library/features/loans/data/datasources/loan_remote_data_source.dart';
import 'package:lore_dungeo_library/features/loans/data/models/loan_response.dart';
import 'package:lore_dungeo_library/features/loans/presentation/providers/loan_provider.dart';
import 'package:lore_dungeo_library/features/loans/presentation/screens/borrowed_loans_screen.dart';
import 'package:lore_dungeo_library/features/users/domain/entities/user.dart';

const _user = User(
  id: 'user-1',
  username: 'reader',
  email: 'reader@example.com',
  fullName: 'Test Reader',
  role: 'USER',
  status: 'ACTIVE',
);

const _loans = PageDTO<LoanResponseDTO>(
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
      dueAt: null,
      renewCount: 1,
      items: [
        {'bookId': 'book-1'},
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

  @override
  String get baseUrl => 'http://localhost:8083';

  @override
  Future<PageDTO<LoanResponseDTO>> getBorrowedLoans(
    String userId, {
    int page = 0,
    int size = 20,
  }) async =>
      _loans;

  @override
  Future<LoanResponseDTO> requestLoan({
    required String userId,
    required List<Map<String, dynamic>> items,
    CancelToken? cancelToken,
  }) async {
    requestedUserId = userId;
    requestedItems = items;
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
}

void main() {
  Future<void> openScreen(
    WidgetTester tester, {
    List<Book> books = const [],
    _FakeLoanRemoteDataSource? remoteDataSource,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loanCurrentUserIdProvider.overrideWith((ref) async => _user.id),
          borrowedLoansProvider('user-1').overrideWith((ref) async => _loans),
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
    expect(find.text('Phiếu loan-1'), findsOneWidget);
    expect(find.text('BORROWED'), findsOneWidget);
    expect(find.text('2 đầu sách  ·  Đã gia hạn 1 lần'), findsOneWidget);
  });

  testWidgets('filters borrowed loans by ID or status', (tester) async {
    await openScreen(tester);

    await tester.enterText(find.byType(TextField), 'requested');
    await tester.pumpAndSettle();

    expect(find.text('Phiếu loan-2'), findsOneWidget);
    expect(find.text('Phiếu loan-1'), findsNothing);
  });

  testWidgets('shows an empty state when search has no matches', (tester) async {
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