import 'package:lore_dungeo_library/features/sign/services/auth_service.dart';
import 'package:lore_dungeo_library/features/sign/models/auth_response.dart';
import 'package:lore_dungeo_library/features/sign/models/login_request.dart';
import 'package:lore_dungeo_library/features/sign/models/register_request.dart';
import 'package:lore_dungeo_library/features/sign/models/user.dart';

class FakeAuthService implements AuthService {
  User? restored;
  int logins = 0;
  int registrations = 0;
  int logouts = 0;
  Future<AuthResponse>? pending;
  bool remember = true;
  static const reader =
      User(id: 'u1', fullName: 'Reader', email: 'user@example.com');

  @override
  Future<User?> restore() async => restored;
  @override
  Future<AuthResponse> login(LoginRequest request,
      {bool remember = true}) async {
    logins++;
    this.remember = remember;
    if (pending != null) return await pending!;
    return const AuthResponse.success(user: reader);
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    registrations++;
    return const AuthResponse.success(
        user: reader, message: 'Đăng ký thành công.');
  }

  @override
  Future<void> logout() async {
    logouts++;
    restored = null;
  }
}
