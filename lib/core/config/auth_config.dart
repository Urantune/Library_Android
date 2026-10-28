import 'package:flutter/foundation.dart';

class AuthConfig {
  static String get baseUrl {
    const configured = String.fromEnvironment('AUTH_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8081'
        : 'http://127.0.0.1:8081';
  }
}
