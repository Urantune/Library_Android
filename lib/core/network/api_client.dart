import 'package:dio/dio.dart';
import '../auth/auth_session.dart';
import '../auth/token_storage.dart';
import '../config/auth_config.dart';
import 'auth_interceptor.dart';

class ApiClient {
  static Dio create(
      {TokenStorage? tokenStorage,
      String? baseUrl,
      void Function()? onSessionExpired}) {
    final options = BaseOptions(
      baseUrl: baseUrl ??
          const String.fromEnvironment('API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8080'),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    );
    final dio = Dio(options);
    final refreshClient = Dio(BaseOptions(
      baseUrl: AuthConfig.baseUrl,
      connectTimeout: options.connectTimeout,
      receiveTimeout: options.receiveTimeout,
      sendTimeout: options.sendTimeout,
    ));
    final storage = tokenStorage ?? TokenStorage.shared;
    dio.interceptors.add(AuthInterceptor(
        dio: dio,
        tokenStorage: storage,
        session: AuthSession.shared(dio: refreshClient, tokenStorage: storage),
        onSessionExpired: onSessionExpired));
    return dio;
  }

  static final Dio dio = create();
  static final Dio catalogDio = create(
      baseUrl: const String.fromEnvironment('CATALOG_API_URL',
          defaultValue: 'http://10.0.2.2:8082'));
}
