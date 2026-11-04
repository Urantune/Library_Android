/// Cấu hình chế độ dữ liệu cho module users.
/// - DATA_MODE = 'demo' (mặc định): đọc từ JSON + SharedPreferences (không cần backend).
/// - DATA_MODE = 'api': gọi REST API thật qua ApiClient (cần backend mss chạy).
class UserConfig {
  static const String dataMode = String.fromEnvironment('DATA_MODE', defaultValue: 'demo');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080');

  static bool get useRemote => dataMode.toLowerCase() == 'api';
}
