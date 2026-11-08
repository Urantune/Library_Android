import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/loans/data/datasources/loan_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<dynamic> _response(String path, Map<String, dynamic> data,
    {int statusCode = 200}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    data: data,
    statusCode: statusCode,
  );
}

void main() {
  late _MockDio dio;
  late LoanRemoteDataSource dataSource;

  setUp(() {
    dio = _MockDio();
    dataSource = LoanRemoteDataSource(
      dio: dio,
      baseUrl: 'http://localhost:8083',
    );
  });

  test('gets and parses the current borrowed-loan page', () async {
    when(() => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => _response(
          '/api/loans/users/user-1/borrowed',
          {
            'message': 'Current borrowed books',
            'result': {
              'size': 20,
              'page': 0,
              'totalPages': 1,
              'totalElements': 1,
              'first': true,
              'last': true,
              'content': [
                {
                  'id': 'loan-1',
                  'userId': 'user-1',
                  'status': 'BORROWED',
                  'requestedAt': '2026-10-24T10:00:00',
                  'dueAt': '2026-11-07T10:00:00',
                  'renewCount': 0,
                  'items': [
                    {'bookId': 'book-1'},
                  ],
                },
              ],
            },
          },
        ));

    final page = await dataSource.getBorrowedLoans('user-1');

    expect(page.totalElements, 1);
    expect(page.content.single.id, 'loan-1');
    expect(page.content.single.status, 'BORROWED');
    expect(page.content.single.dueAt, DateTime(2026, 11, 7, 10));
    expect(page.content.single.items.single['bookId'], 'book-1');
    final options = verify(() => dio.get<dynamic>(
          '/api/loans/users/user-1/borrowed',
          queryParameters: {'page': 0, 'size': 20},
          options: captureAny(named: 'options'),
        )).captured.single as Options;
    expect(options.headers?['X-User-Id'], 'user-1');
  });

  test('posts the loan request with user ID and item payload', () async {
    when(() => dio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => _response('/api/loans', {
          'message': 'Loan request submitted',
          'result': {
            'id': 'loan-2',
            'userId': 'user-1',
            'status': 'REQUESTED',
            'renewCount': 0,
            'items': [],
          },
        }, statusCode: 201));

    final loan = await dataSource.requestLoan(
      userId: 'user-1',
      items: const [
        {'bookId': 'book-1', 'copyId': 'copy-1'},
      ],
    );

    expect(loan.id, 'loan-2');
    expect(loan.status, 'REQUESTED');
    final options = verify(() => dio.post<dynamic>(
          '/api/loans',
          data: {
            'userId': 'user-1',
            'items': [
              {'bookId': 'book-1', 'copyId': 'copy-1'},
            ],
          },
          options: captureAny(named: 'options'),
        )).captured.single as Options;
    expect(options.headers?['X-User-Id'], 'user-1');
  });
}