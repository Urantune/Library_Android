import 'package:dio/dio.dart';

import 'token_storage.dart';

class AuthSession {
  AuthSession({required Dio dio, required TokenStorage tokenStorage}) : _dio = dio, _tokenStorage = tokenStorage;
  final Dio _dio;
  final TokenStorage _tokenStorage;
  Future<String?> refreshAccessToken() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final response = await _dio.post('/api/auth/refresh', data: {'refreshToken': refreshToken}, options: Options(extra: {'skipAuth': true}));
      final body = response.data;
      final data = body is Map && body['data'] is Map ? body['data'] as Map : body as Map;
      final accessToken = '${data['accessToken'] ?? data['access_token'] ?? ''}';
      final nextRefreshToken = '${data['refreshToken'] ?? data['refresh_token'] ?? refreshToken}';
      if (accessToken.isEmpty) return null;
      await _tokenStorage.saveTokens(accessToken: accessToken, refreshToken: nextRefreshToken);
      return accessToken;
    } catch (_) {
      await _tokenStorage.clear();
      return null;
    }
  }
  Future<void> logout() => _tokenStorage.clear();
}
