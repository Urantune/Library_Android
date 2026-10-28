import 'package:dio/dio.dart';
import '../auth/auth_session.dart';
import '../auth/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
      {required Dio dio,
      required TokenStorage tokenStorage,
      required AuthSession session,
      void Function()? onSessionExpired})
      : _dio = dio,
        _tokenStorage = tokenStorage,
        _session = session,
        _onSessionExpired = onSessionExpired;
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final AuthSession _session;
  final void Function()? _onSessionExpired;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      if (options.extra['skipAuth'] != true) {
        final token = await _tokenStorage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
      handler.next(options);
    } catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        request.extra['retried'] == true ||
        request.extra['skipAuth'] == true) {
      handler.next(err);
      return;
    }
    try {
      final current = await _tokenStorage.readAccessToken();
      final access = current != null &&
              request.headers['Authorization'] != 'Bearer $current'
          ? current
          : await _session.refreshAccessToken();
      if (access == null) {
        _onSessionExpired?.call();
        handler.next(err);
        return;
      }
      request.headers['Authorization'] = 'Bearer $access';
      request.extra['retried'] = true;
      handler.resolve(await _dio.fetch(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (other) {
      handler.reject(DioException(requestOptions: request, error: other));
    }
  }
}
