import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/publisher.dart';

class PublisherService {
  // Sử dụng Dio chung của project.
  // Client này đã tích hợp AuthInterceptor và TokenStorage.
  final Dio _dio;

  PublisherService({Dio? dio}) : _dio = dio ?? ApiClient.catalogDio;

  // =========================================================
  // XỬ LÝ RESPONSE
  // =========================================================

  // Hỗ trợ các dạng response:
  // 1. { "data": {...} }
  // 2. { "result": {...} }
  // 3. { "data": { "items": [...] } }
  // 4. { "result": { "content": [...] } }
  // 5. JSON trực tiếp.

  dynamic _unwrap(dynamic value) {
    var current = value;

    for (int i = 0; i < 5; i++) {
      if (current is! Map) break;

      if (current['data'] != null) {
        current = current['data'];
      } else if (current['result'] != null) {
        current = current['result'];
      } else if (current['publisher'] != null) {
        current = current['publisher'];
      } else {
        break;
      }
    }

    return current;
  }

  List<Publisher> _parsePublisherList(dynamic response) {
    final data = _unwrap(response);

    dynamic items;

    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = data['items'] ?? data['content'] ?? data['publishers'];
    }

    if (items is! List) {
      throw const FormatException(
        'Response danh sách nhà xuất bản không hợp lệ.',
      );
    }

    return items.map((item) {
      if (item is! Map) {
        throw const FormatException(
          'Thông tin nhà xuất bản không hợp lệ.',
        );
      }

      return Publisher.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  Publisher _parsePublisher(dynamic response) {
    final data = _unwrap(response);

    if (data is! Map) {
      throw const FormatException(
        'Response chi tiết nhà xuất bản không hợp lệ.',
      );
    }

    return Publisher.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  // =========================================================
  // XỬ LÝ LỖI
  // =========================================================

  String _errorMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final message = responseData['message'] ??
          responseData['error'] ??
          responseData['detail'];

      if (message != null) {
        return message.toString();
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Kết nối đến máy chủ quá thời gian.';

      case DioExceptionType.connectionError:
        return 'Không thể kết nối Backend. Kiểm tra máy chủ và mạng.';

      default:
        return error.message ?? 'Đã xảy ra lỗi khi xử lý nhà xuất bản.';
    }
  }

  // =========================================================
  // GET: DANH SÁCH NHÀ XUẤT BẢN
  // =========================================================

  Future<List<Publisher>> getPublishers() async {
    try {
      final response = await _dio.get(
        '/api/publishers',
        queryParameters: {
          'page': 0,
          'size': 100,
        },
      );

      return _parsePublisherList(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  // =========================================================
  // GET: CHI TIẾT NHÀ XUẤT BẢN
  // =========================================================

  Future<Publisher> getPublisherById(String id) async {
    try {
      final response = await _dio.get(
        '/api/publishers/$id',
      );

      return _parsePublisher(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  // =========================================================
  // POST: THÊM NHÀ XUẤT BẢN
  // =========================================================

  Future<Publisher> createPublisher(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '/api/publishers',
        data: data,
      );

      return _parsePublisher(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  // =========================================================
  // PUT: CẬP NHẬT NHÀ XUẤT BẢN
  // =========================================================

  Future<Publisher> updatePublisher(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/api/publishers/$id',
        data: data,
      );

      return _parsePublisher(response.data);
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }

  // =========================================================
  // DELETE: XÓA NHÀ XUẤT BẢN
  // =========================================================

  Future<void> deletePublisher(String id) async {
    try {
      await _dio.delete(
        '/api/publishers/$id',
      );
    } on DioException catch (error) {
      throw Exception(_errorMessage(error));
    }
  }
}
