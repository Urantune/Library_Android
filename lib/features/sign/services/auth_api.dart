import 'package:dio/dio.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<Response<dynamic>> login(LoginRequest request) => _dio.post(
        '/api/auth/login',
        data: request.toJson(),
        options: Options(extra: {'skipAuth': true}),
      );

  Future<Response<dynamic>> register(RegisterRequest request) => _dio.post(
        '/api/auth/register',
        data: request.toJson(),
        options: Options(extra: {'skipAuth': true}),
      );

  Future<Response<dynamic>> currentUser() => _dio.get('/api/users/me');
  Future<void> logout() async => _dio.post('/api/auth/logout');
}
