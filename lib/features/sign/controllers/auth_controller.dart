import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/config/auth_config.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

final tokenStorageProvider =
    Provider<TokenStorage>((ref) => TokenStorage.shared);
final authDioProvider = Provider<Dio>((ref) {
  final dio = ApiClient.create(
    tokenStorage: ref.watch(tokenStorageProvider),
    baseUrl: AuthConfig.baseUrl,
    onSessionExpired: () => ref.read(authControllerProvider.notifier).expire(),
  );
  ref.onDispose(() => dio.close());
  return dio;
});
final authServiceProvider = Provider<AuthService>((ref) => ApiAuthService(
    dio: ref.watch(authDioProvider), storage: ref.watch(tokenStorageProvider)));
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthState {
  const AuthState(
      {this.user,
      this.isLoading = false,
      this.isRestoring = false,
      this.errorMessage});
  final User? user;
  final bool isLoading;
  final bool isRestoring;
  final String? errorMessage;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(restore);
    return const AuthState(isRestoring: true);
  }

  Future<void> restore() async {
    try {
      final user = await ref
          .read(authServiceProvider)
          .restore()
          .timeout(const Duration(seconds: 20));
      if (ref.mounted) state = AuthState(user: user);
    } catch (error) {
      if (ref.mounted) {
        state = AuthState(
            errorMessage: error is DioException
                ? ApiAuthService.messageFor(error)
                : 'Không thể khôi phục phiên. Vui lòng đăng nhập lại.');
      }
    }
  }

  Future<AuthResponse> login(LoginRequest input, {bool remember = true}) =>
      _run(() => ref.read(authServiceProvider).login(input, remember: remember),
          signIn: true);
  Future<AuthResponse> register(RegisterRequest input) =>
      _run(() => ref.read(authServiceProvider).register(input));

  Future<AuthResponse> _run(Future<AuthResponse> Function() action,
      {bool signIn = false}) async {
    if (state.isLoading || state.isRestoring) {
      return const AuthResponse.failure('Yêu cầu đang được xử lý.');
    }
    state = AuthState(user: state.user, isLoading: true);
    AuthResponse result;
    try {
      result = await action();
    } catch (_) {
      result = const AuthResponse.failure(
          'Không thể xử lý lúc này. Vui lòng thử lại.');
    }
    if (ref.mounted) {
      state = AuthState(
          user: signIn && result.success ? result.user : state.user,
          errorMessage: result.success ? null : result.message);
    }
    return result;
  }

  Future<void> logout() async {
    if (state.isLoading) return;
    state = AuthState(user: state.user, isLoading: true);
    String? error;
    try {
      await ref.read(authServiceProvider).logout();
    } catch (_) {
      error =
          'Không thể xác nhận đăng xuất hoàn toàn. Vui lòng kiểm tra kết nối.';
    }
    if (ref.mounted) state = AuthState(errorMessage: error);
  }

  void expire() {
    if (ref.mounted) {
      state = const AuthState(
          errorMessage: 'Phiên đã hết hạn. Vui lòng đăng nhập lại.');
    }
  }

  void clearError() {
    state = AuthState(
        user: state.user,
        isLoading: state.isLoading,
        isRestoring: state.isRestoring);
  }
}
