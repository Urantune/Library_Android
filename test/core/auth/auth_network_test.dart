import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/core/auth/auth_session.dart';
import 'package:lore_dungeo_library/core/auth/token_storage.dart';
import 'package:lore_dungeo_library/core/network/auth_interceptor.dart';
import 'package:lore_dungeo_library/features/sign/services/auth_service.dart';
import 'package:lore_dungeo_library/features/sign/models/login_request.dart';
import 'package:lore_dungeo_library/features/sign/models/register_request.dart';

class MemoryTokens extends TokenStorage {
  String? access = 'old';
  String? refresh = 'refresh-old';
  bool remember = true;
  @override
  Future<String?> readAccessToken() async => access;
  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<void> saveTokens(
      {required String accessToken,
      required String refreshToken,
      bool? persist}) async {
    access = accessToken;
    refresh = refreshToken;
    if (persist != null) remember = persist;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions) handler;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancelFuture) =>
      handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody reply(int status, Object data,
        {Map<String, List<String>> extra = const {}}) =>
    ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...extra,
    });

const user = {
  'id': 'u1',
  'email': 'user@example.com',
  'fullName': 'Reader',
  'roles': ['MEMBER'],
  'status': 'ACTIVE'
};

void main() {
  test('concurrent 401 responses share one refresh and retry once', () async {
    final tokens = MemoryTokens();
    var refreshes = 0;
    final refresh = Dio(BaseOptions(baseUrl: 'http://unit.test'));
    refresh.httpClientAdapter = StubAdapter((request) async {
      refreshes++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return reply(200, {
        'data': {'accessToken': 'new', 'refreshToken': 'refresh-new'}
      });
    });
    final dio = Dio(BaseOptions(baseUrl: 'http://unit.test'));
    dio.httpClientAdapter = StubAdapter((request) async =>
        request.headers['Authorization'] == 'Bearer new'
            ? reply(200, {'data': user})
            : reply(401, {}));
    dio.interceptors.add(AuthInterceptor(
        dio: dio,
        tokenStorage: tokens,
        session: AuthSession(dio: refresh, tokenStorage: tokens)));
    final result =
        await Future.wait(List.generate(4, (_) => dio.get('/api/users/me')));
    expect(result.every((response) => response.statusCode == 200), isTrue);
    expect(refreshes, 1);
    expect(tokens.refresh, 'refresh-new');
  });

  test('rejected refresh clears tokens and emits expiry without looping',
      () async {
    final tokens = MemoryTokens();
    var expired = 0;
    final refresh = Dio(BaseOptions(baseUrl: 'http://unit.test'))
      ..httpClientAdapter = StubAdapter((_) async => reply(401, {}));
    final dio = Dio(BaseOptions(baseUrl: 'http://unit.test'))
      ..httpClientAdapter = StubAdapter((_) async => reply(401, {}));
    dio.interceptors.add(AuthInterceptor(
        dio: dio,
        tokenStorage: tokens,
        session: AuthSession(dio: refresh, tokenStorage: tokens),
        onSessionExpired: () => expired++));
    await expectLater(dio.get('/api/users/me'), throwsA(isA<DioException>()));
    expect(tokens.access, isNull);
    expect(tokens.refresh, isNull);
    expect(expired, 1);
  });

  test('login uses real transport and honors remember-session setting',
      () async {
    final tokens = MemoryTokens();
    final dio = Dio(BaseOptions(baseUrl: 'http://unit.test'));
    dio.httpClientAdapter = StubAdapter((request) async {
      expect(request.path, '/api/auth/login');
      expect(request.extra['skipAuth'], true);
      return reply(200, {
        'data': {
          'user': user,
          'accessToken': 'access',
          'refreshToken': 'refresh'
        }
      });
    });
    final result = await ApiAuthService(dio: dio, storage: tokens).login(
        const LoginRequest(email: 'user@example.com', password: 'Password123!'),
        remember: false);
    expect(result.success, true);
    expect(result.user!.email, 'user@example.com');
    expect(tokens.access, 'access');
    expect(tokens.remember, false);
  });

  test('register does not create a client session or store a password',
      () async {
    final tokens = MemoryTokens()
      ..access = null
      ..refresh = null;
    final dio = Dio(BaseOptions(baseUrl: 'http://unit.test'))
      ..httpClientAdapter =
          StubAdapter((_) async => reply(201, {'data': user}));
    final result = await ApiAuthService(dio: dio, storage: tokens).register(
        const RegisterRequest(
            fullName: 'Reader',
            email: 'user@example.com',
            password: 'Password123!'));
    expect(result.success, true);
    expect(tokens.access, isNull);
    expect(tokens.refresh, isNull);
  });

  test('field errors and throttling are readable and logout clears on failure',
      () async {
    final tokens = MemoryTokens();
    final dio = Dio(BaseOptions(baseUrl: 'http://unit.test'))
      ..httpClientAdapter =
          StubAdapter((request) async => request.path.endsWith('/logout')
              ? reply(503, {})
              : reply(429, {}, extra: {
                  'retry-after': ['30']
                }));
    final service = ApiAuthService(dio: dio, storage: tokens);
    final result = await service
        .login(const LoginRequest(email: 'a@b.com', password: 'Password123!'));
    expect(result.message, contains('30 giây'));
    await expectLater(service.logout(), throwsA(isA<DioException>()));
    expect(tokens.access, isNull);
    expect(tokens.refresh, isNull);
    dio.httpClientAdapter = StubAdapter((_) async => reply(400, {
          'fieldErrors': {'email': 'Email không hợp lệ.'}
        }));
    expect(
        (await service.register(const RegisterRequest(
                fullName: 'R', email: 'bad', password: '1')))
            .message,
        'Email không hợp lệ.');
  });

  test('refresh network failure preserves persisted session for a later retry',
      () async {
    final tokens = MemoryTokens();
    final dio = Dio(BaseOptions(baseUrl: 'http://unit.test'))
      ..httpClientAdapter = StubAdapter((request) async => throw DioException(
          requestOptions: request, type: DioExceptionType.connectionTimeout));
    await expectLater(
        AuthSession(dio: dio, tokenStorage: tokens).refreshAccessToken(),
        throwsA(isA<DioException>()));
    expect(tokens.access, 'old');
    expect(tokens.refresh, 'refresh-old');
  });
}
