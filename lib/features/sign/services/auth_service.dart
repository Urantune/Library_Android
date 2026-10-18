import '../constants/auth_constants.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user.dart';


abstract class AuthService {
  Future<AuthResponse> login(LoginRequest request);
  Future<AuthResponse> register(RegisterRequest request);
}

/// Tài khoản mẫu: daibangtungcanh@gmail.com / 123456
class MockAuthService implements AuthService {
  static final Map<String, _MockAccount> _accounts = {
    'daibangtungcanh@gmail.com': _MockAccount(
      user: const User(
        id: '1',
        fullName: 'Tong Tai Ba Khi',
        email: 'daibangtungcanh@gmail.com',
      ),
      password: '123456',
    ),
  };

  static const Duration _latency = Duration(milliseconds: 800);

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    await Future.delayed(_latency);
    final account = _accounts[request.email.trim().toLowerCase()];
    if (account == null || account.password != request.password) {
      return const AuthResponse.failure(AuthStrings.wrongCredentials);
    }
    return AuthResponse.success(
      user: account.user,
      message: AuthStrings.loginSuccess,
    );
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    await Future.delayed(_latency);
    final email = request.email.trim().toLowerCase();
    if (_accounts.containsKey(email)) {
      return const AuthResponse.failure(AuthStrings.emailExists);
    }
    final user = User(
      id: (_accounts.length + 1).toString(),
      fullName: request.fullName.trim(),
      email: email,
    );
    _accounts[email] = _MockAccount(user: user, password: request.password);
    return AuthResponse.success(
      user: user,
      message: AuthStrings.registerSuccess,
    );
  }
}

class _MockAccount {
  final User user;
  final String password;
  _MockAccount({required this.user, required this.password});
}
