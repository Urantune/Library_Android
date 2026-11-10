import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/reservations/services/reservation_service.dart';
import 'package:mocktail/mocktail.dart';

/// Nguyen Duy Khang
/// Giả lập Dio để kiểm tra request mà không gọi Backend thật.
class _MockDio extends Mock implements Dio {}

void main() {
  late Dio dio;
  late ReservationService service;

  setUpAll(() => registerFallbackValue(Options()));

  setUp(() {
    dio = _MockDio();
    service = ReservationService(dio: dio);
  });

  test('POST đúng Gateway route, bookId và Idempotency-Key', () async {
    when(
      () => dio.post<dynamic>(
        '/reservation/api/reservations',
        data: {'bookId': 'book-01'},
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/reservation/api/reservations'),
        statusCode: 201,
        data: {
          'status': 201,
          'data': {
            'id': 'reservation-01',
            'userId': 'user-01',
            'bookId': 'book-01',
            'status': 'WAITING',
            'queuePosition': 2,
            'createdAt': '2026-11-10T10:00:00Z',
          },
        },
      ),
    );

    final result = await service.createReservation(' book-01 ');

    expect(result.id, 'reservation-01');
    expect(result.queuePosition, 2);
    final options = verify(
      () => dio.post<dynamic>(
        '/reservation/api/reservations',
        data: {'bookId': 'book-01'},
        options: captureAny(named: 'options'),
      ),
    ).captured.single as Options;
    expect(
      options.headers?['Idempotency-Key'],
      matches(RegExp(r'^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$')),
    );
  });

  test('đổi lỗi đặt trùng thành thông báo tiếng Việt', () async {
    final request = RequestOptions(path: '/reservation/api/reservations');
    when(
      () => dio.post<dynamic>(
        '/reservation/api/reservations',
        data: {'bookId': 'book-01'},
        options: any(named: 'options'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 409,
          data: {'code': 'DUPLICATE_ACTIVE_RESERVATION'},
        ),
      ),
    );

    expect(
      () => service.createReservation('book-01'),
      throwsA(
        predicate(
          (error) => error.toString().contains('đã có một lượt đặt trước'),
        ),
      ),
    );
  });

  test('GET danh sách đặt trước của tài khoản', () async {
    when(
      () => dio.get<dynamic>(
        '/reservation/api/reservations/me',
        queryParameters: {'page': 0, 'size': 100},
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions:
            RequestOptions(path: '/reservation/api/reservations/me'),
        data: {
          'data': {
            'items': [
              {
                'id': 'reservation-01',
                'userId': 'user-01',
                'bookId': 'book-01',
                'status': 'WAITING',
                'queuePosition': 1,
              },
            ],
            'totalPages': 1,
          },
        },
      ),
    );

    final result = await service.getMyReservations();

    expect(result, hasLength(1));
    expect(result.single.status, 'WAITING');
  });

  test('DELETE gọi đúng endpoint hủy đặt trước', () async {
    when(
      () => dio.delete<dynamic>(
        '/reservation/api/reservations/reservation%2F01',
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/reservation/api/reservations'),
        statusCode: 204,
      ),
    );

    await service.cancelReservation('reservation/01');

    verify(
      () => dio.delete<dynamic>(
        '/reservation/api/reservations/reservation%2F01',
      ),
    ).called(1);
  });
}
