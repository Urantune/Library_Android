import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/core/auth/token_storage.dart';
import 'package:lore_dungeo_library/core/network/api_client.dart';
import 'package:lore_dungeo_library/features/sign/models/login_request.dart';
import 'package:lore_dungeo_library/features/sign/models/register_request.dart';
import 'package:lore_dungeo_library/features/sign/services/auth_service.dart';

void main() {
  test(
      'real Identity HTTP: register, login, restore, refresh and revoke logout',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final original = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = original);
    FlutterSecureStorage.setMockInitialValues({});
    const base = String.fromEnvironment('AUTH_BASE_URL',
        defaultValue: 'http://127.0.0.1:8081');
    final storage = TokenStorage();
    final dio = ApiClient.create(baseUrl: base, tokenStorage: storage);
    final raw = Dio(BaseOptions(baseUrl: base));
    addTearDown(() {
      dio.close();
      raw.close();
    });
    final service = ApiAuthService(dio: dio, storage: storage);
    final email =
        'auth-check-${DateTime.now().microsecondsSinceEpoch}@example.com';
    const password = 'AuthLivePassword123!';
    final registered = await service.register(RegisterRequest(
        fullName: 'Auth Check', email: email, password: password));
    expect(registered.success, isTrue, reason: registered.message);
    final loggedIn =
        await service.login(LoginRequest(email: email, password: password));
    expect(loggedIn.success, isTrue, reason: loggedIn.message);
    expect((await service.restore())?.email, email);
    final refresh = (await storage.readRefreshToken())!;
    await storage.saveTokens(
        accessToken: 'expired-token', refreshToken: refresh);
    expect((await service.restore())?.email, email);
    expect(await storage.readRefreshToken(), isNot(refresh));
    final access = await storage.readAccessToken();
    await service.logout();
    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
    await expectLater(
        raw.get('/api/users/me',
            options: Options(headers: {'Authorization': 'Bearer $access'})),
        throwsA(isA<DioException>()
            .having((e) => e.response?.statusCode, 'status', 401)));
  }, skip: !const bool.fromEnvironment('RUN_LIVE_AUTH'));
}
