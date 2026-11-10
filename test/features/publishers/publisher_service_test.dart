import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/publishers/services/publisher_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

Response<dynamic> _response(dynamic data, {int statusCode = 200}) {
  return Response<dynamic>(
    data: data,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: '/api/publishers'),
  );
}

Map<String, dynamic> _publisherJson(String id, String name) {
  return {
    'id': id,
    'name': name,
    'address': 'TP.HCM',
    'email': 'contact@example.com',
    'phone': '0123456789',
    'website': 'https://example.com',
    'status': 'ACTIVE',
  };
}

void main() {
  late Dio dio;
  late PublisherService service;

  setUp(() {
    dio = _MockDio();
    service = PublisherService(dio: dio);
  });

  test('thử lại không có token khi catalog local trả về 401', () async {
    const query = {'status': 'ACTIVE', 'page': 0, 'size': 100};
    final request = RequestOptions(path: '/api/publishers');
    final skipsAuth = isA<Options>().having(
      (options) => options.extra?['skipAuth'],
      'skipAuth',
      isTrue,
    );
    when(
      () => dio.get<dynamic>('/api/publishers', queryParameters: query),
    ).thenThrow(
      DioException(
        requestOptions: request,
        response: Response<dynamic>(requestOptions: request, statusCode: 401),
      ),
    );
    when(
      () => dio.get<dynamic>(
        '/api/publishers',
        queryParameters: query,
        options: any(named: 'options', that: skipsAuth),
      ),
    ).thenAnswer(
      (_) async => _response({
        'data': {'items': <dynamic>[], 'totalPages': 0},
      }),
    );

    final result = await service.getPublishers();

    expect(result, isEmpty);
    verify(
      () => dio.get<dynamic>(
        '/api/publishers',
        queryParameters: query,
        options: any(named: 'options', that: skipsAuth),
      ),
    ).called(1);
  });

  group('PRM-023 - xem nhà xuất bản', () {
    test('đọc đủ các trang trong response data.items', () async {
      when(
        () => dio.get<dynamic>(
          '/api/publishers',
          queryParameters: {'status': 'ACTIVE', 'page': 0, 'size': 100},
        ),
      ).thenAnswer(
        (_) async => _response({
          'data': {
            'items': [_publisherJson('p1', 'NXB Trẻ')],
            'totalPages': 2,
          },
        }),
      );
      when(
        () => dio.get<dynamic>(
          '/api/publishers',
          queryParameters: {'status': 'ACTIVE', 'page': 1, 'size': 100},
        ),
      ).thenAnswer(
        (_) async => _response({
          'data': {
            'items': [_publisherJson('p2', 'NXB Kim Đồng')],
            'totalPages': 2,
          },
        }),
      );

      final result = await service.getPublishers();

      expect(result.map((item) => item.id), ['p1', 'p2']);
    });

    test('đọc chi tiết và mã hóa ID trên URL', () async {
      when(() => dio.get<dynamic>('/api/publishers/pub%2F01')).thenAnswer(
        (_) async => _response({'data': _publisherJson('pub/01', 'NXB Trẻ')}),
      );

      final result = await service.getPublisherById('pub/01');

      expect(result.name, 'NXB Trẻ');
    });
  });

  test('PRM-024 - POST gửi đúng dữ liệu đã chuẩn hóa', () async {
    when(
      () => dio.post<dynamic>(
        '/api/publishers',
        data: {
          'name': 'NXB Trẻ',
          'email': 'contact@example.com',
          'status': 'ACTIVE',
        },
      ),
    ).thenAnswer(
      (_) async => _response(
        {'data': _publisherJson('p1', 'NXB Trẻ')},
        statusCode: 201,
      ),
    );

    final result = await service.createPublisherData(
      name: '  NXB Trẻ  ',
      email: ' contact@example.com ',
      address: ' ',
    );

    expect(result.id, 'p1');
  });

  test('PRM-025 - PUT giữ trạng thái và mã hóa ID', () async {
    when(
      () => dio.put<dynamic>(
        '/api/publishers/pub%2F01',
        data: {
          'name': 'NXB Mới',
          'status': 'ACTIVE',
        },
      ),
    ).thenAnswer(
      (_) async => _response({'data': _publisherJson('pub/01', 'NXB Mới')}),
    );

    final result = await service.updatePublisherData(
      id: 'pub/01',
      name: 'NXB Mới',
      status: 'ACTIVE',
    );

    expect(result.name, 'NXB Mới');
  });

  test('PRM-026 - DELETE gọi đúng endpoint', () async {
    when(() => dio.delete<dynamic>('/api/publishers/pub%2F01')).thenAnswer(
      (_) async => _response(null, statusCode: 204),
    );

    await service.deletePublisher('pub/01');

    verify(() => dio.delete<dynamic>('/api/publishers/pub%2F01')).called(1);
  });
}
