import 'api_config.dart';

class AuthConfig {
  static String get baseUrl {
    const configured = String.fromEnvironment('AUTH_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return ApiConfig.baseUrl;
  }
}
