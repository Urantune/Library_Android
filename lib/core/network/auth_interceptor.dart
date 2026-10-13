import 'package:dio/dio.dart';

import '../auth/auth_session.dart';
import '../auth/token_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required TokenStorage tokenStorage, required AuthSession session}) : _tokenStorage = tokenStorage, _session = session;
  final TokenStorage _tokenStorage;
  final AuthSession _session;
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['skipAuth'] == true) return handler.next(options);
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }
  @override
  Future<void> onError(DioException error, ErrorInterceptorHandler handler) async {
    final request = error.requestOptions;
    if (error.response?.statusCode != 401 || request.extra['retried'] == true || request.extra['skipAuth'] == true) return handler.next(error);
    final accessToken = await _session.refreshAccessToken();
    if (accessToken == null) return handler.next(error);
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.extra['retried'] = true;
    try {
      handler.resolve(await Dio(BaseOptions(baseUrl: request.baseUrl)).fetch(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
