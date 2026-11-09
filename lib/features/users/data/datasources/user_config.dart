import '../../../../core/config/api_config.dart';

/// Cấu hình chế độ dữ liệu cho module users.
/// - DATA_MODE = 'api' (mặc định): đọc/ghi từ backend qua Gateway.
/// - DATA_MODE = 'demo': đọc từ JSON + SharedPreferences.
class UserConfig {
  UserConfig._();

  static const String dataMode =
      String.fromEnvironment('DATA_MODE', defaultValue: 'api');

  static String get apiBaseUrl => ApiConfig.baseUrl;

  static bool get useRemote => dataMode.toLowerCase() == 'api';
}
