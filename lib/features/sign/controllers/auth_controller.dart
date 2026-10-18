import 'package:flutter/foundation.dart';

import '../constants/auth_constants.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthService? service})
      : _service = service ?? MockAuthService();

  final AuthService _service;

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  Future<AuthResponse> login(LoginRequest request) =>
      _run(() => _service.login(request), saveUser: true);

  Future<AuthResponse> register(RegisterRequest request) =>
      _run(() => _service.register(request));

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<AuthResponse> _run(
    Future<AuthResponse> Function() action, {
    bool saveUser = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    AuthResponse response;
    try {
      response = await action();
    } catch (_) {
      response = const AuthResponse.failure(AuthStrings.unknownError);
    }

    if (response.success) {
      if (saveUser) _currentUser = response.user;
    } else {
      _errorMessage = response.message;
    }
    _isLoading = false;
    notifyListeners();
    return response;
  }
}
