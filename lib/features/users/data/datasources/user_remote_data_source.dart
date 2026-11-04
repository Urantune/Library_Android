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
  Future<List<User>> getUsers() async {
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
  }

  Future<User> getMe() async {
    final response = await _dio.get('/api/users/me');
    return User.fromJson(Map<String, dynamic>.from(_extractData(response.data) as Map));
  }

  Future<void> updateMe(User user) async {
    await _dio.put('/api/users/me', data: {
      'fullName': user.fullName,
      'phone': user.phone,
    });
  }

  /// Lấy chi tiết một người dùng (GET /api/users/{id})
  Future<User> getUserById(String id) async {
    final response = await _dio.get('/api/users/$id');
    final data = _extractData(response.data);
    return User.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Tạo người dùng mới (POST /api/users)
  Future<void> createUser(User user, {required String password}) async {
    await _dio.post('/api/users', data: {
      'username': user.username,
      'email': user.email,
      'fullName': user.fullName,
      'phone': user.phone,
      'role': _apiRole(user.role),
      'password': password,
    });
  }

  /// Cập nhật người dùng (PUT /api/users/{id})
  Future<void> updateUser(User user) async {
    await _dio.put('/api/users/${user.id}', data: {
      'username': user.username,
      'email': user.email,
      'fullName': user.fullName,
      'phone': user.phone,
      'role': _apiRole(user.role),
    });
  }

  /// Xóa người dùng (DELETE /api/users/{id})
  Future<void> deleteUser(String id) async {
    await _dio.delete('/api/users/$id');
  }

  /// Khóa người dùng (PATCH /api/users/{id}/status)
  Future<void> lockUser(String id) async {
    await _dio.patch('/api/users/$id/status', data: {'status': 'LOCKED'});
  }

  /// Mở khóa người dùng (PATCH /api/users/{id}/status)
  Future<void> unlockUser(String id) async {
    await _dio.patch('/api/users/$id/status', data: {'status': 'ACTIVE'});
  }

  String _apiRole(String role) => switch (role.toUpperCase()) {
        'USER' || 'MEMBER' => 'MEMBER',
        'STAFF' || 'LIBRARIAN' => 'LIBRARIAN',
        _ => 'ADMIN',
      };

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
