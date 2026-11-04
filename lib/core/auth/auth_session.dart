import 'package:dio/dio.dart';
import 'token_storage.dart';

class AuthSession {
  static final _shared = Expando<AuthSession>();
  static AuthSession shared(
          {required Dio dio, required TokenStorage tokenStorage}) =>
      _shared[tokenStorage] ??=
          AuthSession(dio: dio, tokenStorage: tokenStorage);
  AuthSession({required Dio dio, required TokenStorage tokenStorage})
      : _dio = dio,
        _tokenStorage = tokenStorage;
  final Dio _dio;
  final TokenStorage _tokenStorage;
  Future<String?>? _refreshing;

  Future<String?> refreshAccessToken() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<String?> _refresh() async {
    final token = await _tokenStorage.readRefreshToken();
    if (token == null || token.isEmpty) return null;
    try {
      final response =
          await _dio.post('/api/auth/refresh', data: {'refreshToken': token});
      final body = Map<String, dynamic>.from(response.data as Map);
      final data = Map<String, dynamic>.from(body['data'] as Map);
      final access = data['accessToken'] as String;
      final refresh = data['refreshToken'] as String;
      if (access.isEmpty || refresh.isEmpty) {
        throw const FormatException('Invalid session');
      }
      await _tokenStorage.saveTokens(
          accessToken: access, refreshToken: refresh);
      return access;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        await _tokenStorage.clear();
        return null;
      }
      rethrow;
    } on FormatException {
      await _tokenStorage.clear();
      return null;
    } on TypeError {
      await _tokenStorage.clear();
      return null;
    }
  }
}
