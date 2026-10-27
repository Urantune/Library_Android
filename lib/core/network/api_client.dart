import 'package:dio/dio.dart';

import '../auth/auth_session.dart';
import '../auth/token_storage.dart';
import 'auth_interceptor.dart';

class ApiClient {
  static Dio create({TokenStorage? tokenStorage, String? baseUrl}) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8080',
      ),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ));
    final storage = tokenStorage ?? const TokenStorage();
    dio.interceptors.add(AuthInterceptor(tokenStorage: storage, session: AuthSession(dio: dio, tokenStorage: storage)));
    return dio;
  }

  static final Dio dio = create();

  /// Direct Catalog service client for local Android development. Override with
  /// `--dart-define=CATALOG_API_URL=https://your-host` when required.
  static final Dio catalogDio = create(
    baseUrl: const String.fromEnvironment(
      'CATALOG_API_URL',
      defaultValue: 'http://10.0.2.2:8082',
    ),
  );
}
