import 'user.dart';

class AuthResponse {
  final bool success;
  final String message;
  final User? user;
  final bool connectionError;

  const AuthResponse({
    required this.success,
    required this.message,
    this.user,
    this.connectionError = false,
  });

  const AuthResponse.success({required this.user, this.message = ''})
      : success = true, connectionError = false;

  const AuthResponse.failure(this.message, {this.connectionError = false})
      : success = false,
        user = null;
}
