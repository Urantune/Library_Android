import 'package:dio/dio.dart';

import '../models/book_category.dart';
import '../models/page_result.dart';
import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

class CategoryApiService {
  CategoryApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Content-Type': 'application/json'},
            ));

  final Dio _dio;
  static const _path = '/api/categories';

  Future<PageResult<BookCategory>> search({
    String keyword = '',
    required int page,
    required int size,
  }) =>
      _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          _path,
          queryParameters: {
            if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
            'status': 'ACTIVE',
            'page': page - 1,
            'size': size,
            'sort': 'name,asc',
          },
        );
        return PageResult.fromJson(res.data ?? {}, BookCategory.fromJson);
      });

  Future<List<BookCategory>> listActive({int limit = 1000}) async {
    final result = await search(page: 1, size: limit);
    return result.content;
  }

  Future<BookCategory> getById(String id) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('$_path/$id');
        return BookCategory.fromJson(res.data ?? {});
      });

  Future<BookCategory> create({
    required String name,
    required String description,
    String? parentId,
  }) =>
      _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          _path,
          data: _body(name, description, parentId),
        );
        return BookCategory.fromJson(res.data ?? {});
      });

  Future<BookCategory> update(
    String id, {
    required String name,
    required String description,
    String? parentId,
  }) =>
      _guard(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          '$_path/$id',
          data: _body(name, description, parentId),
        );
        return BookCategory.fromJson(res.data ?? {});
      });

  Future<void> delete(String id) => _guard(() async {
        await _dio.delete('$_path/$id');
      });

  Future<BookCategory> restore(String id) => _guard(() async {
        final res = await _dio.patch<Map<String, dynamic>>('$_path/$id/restore');
        return BookCategory.fromJson(res.data ?? {});
      });

  Map<String, dynamic> _body(String name, String description, String? parentId) =>
      {
        'name': name,
        'description': description,
        'parentId': (parentId == null || parentId.isEmpty) ? null : parentId,
      };

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('Máy chủ phản hồi quá lâu, vui lòng thử lại');
      case DioExceptionType.connectionError:
        return const ApiException(
            'Không kết nối được tới máy chủ, kiểm tra API Gateway đã chạy chưa');
      default:
        break;
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? serverMsg;
    if (data is Map) {
      final m = data['message'] ?? data['detail'] ?? data['error'];
      if (m is String && m.trim().isNotEmpty) serverMsg = m;
    }

    final fallback = switch (status) {
      400 => 'Dữ liệu không hợp lệ',
      404 => 'Không tìm thấy thể loại này',
      409 => 'Tên thể loại đã tồn tại',
      final int s when s >= 500 => 'Máy chủ gặp lỗi ($s)',
      _ => 'Lỗi không xác định${status != null ? ' ($status)' : ''}',
    };
    return ApiException(serverMsg ?? fallback, statusCode: status);
  }
}
