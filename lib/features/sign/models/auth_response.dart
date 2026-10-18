import 'user.dart';

class AuthResponse {
  final bool success;
  final String message;
  final User? user;

  const AuthResponse({
    required this.success,
    required this.message,
    this.user,
  });

  const AuthResponse.success({required this.user, this.message = ''})
      : success = true;

  const AuthResponse.failure(this.message)
      : success = false,
        user = null;
}
