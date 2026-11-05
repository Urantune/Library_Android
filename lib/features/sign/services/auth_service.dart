import 'package:dio/dio.dart';
import '../../../core/auth/token_storage.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user.dart';

abstract class AuthService {
  Future<AuthResponse> login(LoginRequest request, {bool remember = true});
  Future<AuthResponse> register(RegisterRequest request);
  Future<User?> restore();
  Future<void> logout();
}

class ApiAuthService implements AuthService {
  ApiAuthService({required Dio dio, required TokenStorage storage})
      : _dio = dio,
        _storage = storage;
  final Dio _dio;
  final TokenStorage _storage;

  Map<String, dynamic> _data(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map || body['data'] is! Map) {
      throw const FormatException('Invalid API response envelope');
    }
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  @override
  Future<AuthResponse> login(LoginRequest request,
      {bool remember = true}) async {
    late final Response<dynamic> response;
    try {
      response = await _dio.post('/api/auth/login',
          data: request.toJson(), options: Options(extra: {'skipAuth': true}));
    } on DioException catch (error) {
      return AuthResponse.failure(messageFor(error));
    }

    late final Map<String, dynamic> session;
    late final User user;
    try {
      session = _data(response);
      final rawUser = session['user'];
      final accessToken = session['accessToken'];
      final refreshToken = session['refreshToken'];
      if (rawUser is! Map ||
          accessToken is! String ||
          accessToken.isEmpty ||
          refreshToken is! String ||
          refreshToken.isEmpty) {
        throw const FormatException('Incomplete login session');
      }
      user = User.fromJson(Map<String, dynamic>.from(rawUser));
    } catch (_) {
      return const AuthResponse.failure(
          'Backend trả về dữ liệu đăng nhập không hợp lệ.');
    }

    try {
      await _storage.saveTokens(
          accessToken: session['accessToken'] as String,
          refreshToken: session['refreshToken'] as String,
          persist: remember);
      return AuthResponse.success(user: user, message: 'Đăng nhập thành công.');
    } catch (_) {
      return const AuthResponse.failure(
          'Không lưu được phiên đăng nhập. Kiểm tra Secure Storage trên thiết bị.');
    }
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post('/api/auth/register',
          data: request.toJson(), options: Options(extra: {'skipAuth': true}));
      return AuthResponse.success(
          user: User.fromJson(_data(response)),
          message: 'Đăng ký thành công. Hãy đăng nhập để tiếp tục.');
    } on DioException catch (error) {
      return AuthResponse.failure(messageFor(error));
    } catch (_) {
      return const AuthResponse.failure('Không thể đọc phản hồi đăng ký.');
    }
  }

  @override
  Future<User?> restore() async {
    if (await _storage.readAccessToken() == null) return null;
    try {
      return User.fromJson(_data(await _dio.get('/api/users/me')));
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await _storage.clear();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } finally {
      await _storage.clear();
    }
  }

  static String messageFor(DioException error) {
    if (error.response?.statusCode == 429) {
      final seconds = error.response?.headers.value('retry-after');
      return 'Thao tác quá nhiều lần. Vui lòng thử lại${seconds == null ? ' sau.' : ' sau $seconds giây.'}';
    }
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
    if (status == 502 || status == 503 || status == 504) {
      return 'Backend chưa sẵn sàng ($status). Kiểm tra API Gateway và identity-service.';
    }
    if (status != null && status >= 500) {
      return 'Backend gặp lỗi ($status). Kiểm tra log identity-service.';
    }
    if (status == 401 || status == 403) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (status == 400 || status == 422) {
      return 'Thông tin đăng nhập không hợp lệ. Kiểm tra email và mật khẩu.';
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'Kết nối quá thời gian. Vui lòng thử lại.',
      DioExceptionType.connectionError =>
        'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.',
      _ => 'Không thể xử lý lúc này. Vui lòng thử lại sau.',
    };
  }
}
