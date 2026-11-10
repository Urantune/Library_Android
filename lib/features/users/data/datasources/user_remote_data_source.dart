import 'package:dio/dio.dart';

import '../../domain/entities/user.dart';
import '../../../../core/network/api_client.dart';
import '../datasources/user_config.dart';

/// Gọi API users thật qua Dio (có sẵn AuthInterceptor trong ApiClient).
class UserRemoteDataSource {
  UserRemoteDataSource({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = ApiClient.dio;
    // Đảm bảo baseUrl trỏ tới Gateway (theo user_config)
    final base = UserConfig.apiBaseUrl;
    if (base.isNotEmpty) dio.options.baseUrl = base;
    return dio;
  }

  final Dio _dio;

  /// Lấy danh sách người dùng (GET /api/users)
  Future<List<User>> getUsers() => _guard(() async {
        final users = <User>[];
        var page = 0;
        var totalPages = 1;
        do {
          final response = await _dio.get(
            '/api/users',
            queryParameters: {'page': page, 'size': 100},
          );
          final data = _extractData(response.data);
          final items = _extractItems(data);
          users.addAll(items.map(
            (item) => User.fromJson(Map<String, dynamic>.from(item as Map)),
          ));
          if (data is Map && data['totalPages'] is num) {
            totalPages = (data['totalPages'] as num).toInt();
          }
          page++;
        } while (page < totalPages);
        return users;
      });

  /// Lấy hồ sơ đầy đủ của chính mình (GET /api/users/me/profile).
  ///
  /// Endpoint `/me/profile` trả đủ username/SĐT/ngày tạo cho mọi vai trò.
  /// Nếu backend/gateway cũ chưa có endpoint này thì quay về `/me` cơ bản và
  /// bổ sung dữ liệu chi tiết khi người dùng là ADMIN.
  Future<User> getMe() => _guard(() async {
        try {
          final response = await _dio.get('/api/users/me/profile');
          return User.fromJson(
            Map<String, dynamic>.from(_extractData(response.data) as Map),
          );
        } on DioException catch (error) {
          final status = error.response?.statusCode;
          if (status != 403 && status != 404 && status != 405) rethrow;
        }
        final response = await _dio.get('/api/users/me');
        final me = User.fromJson(
          Map<String, dynamic>.from(_extractData(response.data) as Map),
        );
        if (me.role.toUpperCase() != 'ADMIN' || me.id.isEmpty) return me;
        if (me.username.isNotEmpty && me.phone != null && me.createdAt != null) {
          return me;
        }
        try {
          return await getUserById(me.id);
        } on Exception {
          return me;
        }
      });

  /// Cập nhật hồ sơ cá nhân (PUT /api/users/me).
  /// Backend chỉ cho phép đổi fullName và phone.
  Future<User> updateMe(User user) => _guard(() async {
        final response = await _dio.put('/api/users/me', data: {
          'fullName': user.fullName,
          'phone': user.phone,
        });
        return User.fromJson(
          Map<String, dynamic>.from(_extractData(response.data) as Map),
        );
      });

  /// Lấy chi tiết một người dùng (GET /api/users/{id})
  Future<User> getUserById(String id) => _guard(() async {
        final response = await _dio.get('/api/users/$id');
        final data = _extractData(response.data);
        return User.fromJson(Map<String, dynamic>.from(data as Map));
      });

  /// Tạo người dùng mới (POST /api/users)
  Future<void> createUser(User user, {required String password}) =>
      _guard(() async {
        await _dio.post('/api/users', data: {
          'username': user.username,
          'email': user.email,
          'fullName': user.fullName,
          'phone': user.phone,
          'role': _apiRole(user.role),
          'password': password,
        });
      });

  /// Cập nhật người dùng (PUT /api/users/{id})
  Future<void> updateUser(User user) => _guard(() async {
        await _dio.put('/api/users/${user.id}', data: {
          'username': user.username,
          'email': user.email,
          'fullName': user.fullName,
          'phone': user.phone,
          'role': _apiRole(user.role),
        });
      });

  /// Xóa người dùng (DELETE /api/users/{id})
  Future<void> deleteUser(String id) => _guard(() async {
        await _dio.delete('/api/users/$id');
      });

  /// Khóa người dùng (PATCH /api/users/{id}/status)
  Future<void> lockUser(String id) => _guard(() async {
        await _dio.patch('/api/users/$id/status', data: {'status': 'LOCKED'});
      });

  /// Mở khóa người dùng (PATCH /api/users/{id}/status)
  Future<void> unlockUser(String id) => _guard(() async {
        await _dio.patch('/api/users/$id/status', data: {'status': 'ACTIVE'});
      });

  String _apiRole(String role) =>
      role.toUpperCase() == 'ADMIN' ? 'ADMIN' : 'USER';

  /// Chuyển lỗi Dio thành thông điệp dễ hiểu cho người dùng.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw Exception(_readableError(error));
    }
  }

  String _readableError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final fields = data['fieldErrors'];
      if (fields is Map && fields.isNotEmpty) {
        return fields.values.first.toString();
      }
      for (final key in const ['message', 'detail', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value;
      }
    }
    final status = error.response?.statusCode;
    if (status == 400) return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
    if (status == 401) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (status == 403) return 'Bạn không có quyền thực hiện thao tác này.';
    if (status == 404) return 'Không tìm thấy người dùng.';
    if (status == 409) return 'Email hoặc tên đăng nhập đã tồn tại.';
    if (status != null && status >= 500) {
      return 'Máy chủ gặp lỗi ($status). Vui lòng thử lại sau.';
    }
    return 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.';
  }

  /// Trích xuất trường 'data' từ envelope {status,message,data,timestamp,traceId}
  dynamic _extractData(dynamic body) {
    if (body is Map) {
      if (body.containsKey('data')) return body['data'];
      return body;
    }
    throw Exception('Phản hồi API không hợp lệ.');
  }

  /// Trích xuất danh sách items từ data (có thể là list trực tiếp hoặc {items, ...})
  List<dynamic> _extractItems(dynamic data) {
    if (data is List) return data;
    if (data is Map && data.containsKey('items')) {
      final items = data['items'];
      if (items is List) return items;
    }
    throw Exception('Không thể phân tích danh sách người dùng từ phản hồi API.');
  }
}
