import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lore_dungeo_library/core/auth/token_storage.dart';

class _SecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _SecureStorage secureStorage;
  late TokenStorage storage;

  setUp(() {
    secureStorage = _SecureStorage();
    storage = TokenStorage(secureStorage);
  });

  test('stores and reads the access and refresh tokens independently',
      () async {
    when(() => secureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'))).thenAnswer((_) async {});
    when(() => secureStorage.read(key: 'access_token'))
        .thenAnswer((_) async => 'access-1');
    when(() => secureStorage.read(key: 'refresh_token'))
        .thenAnswer((_) async => 'refresh-1');

    await storage.saveTokens(
        accessToken: 'access-1', refreshToken: 'refresh-1');

    expect(await storage.readAccessToken(), 'access-1');
    expect(await storage.readRefreshToken(), 'refresh-1');
    verify(() => secureStorage.write(key: 'access_token', value: 'access-1'))
        .called(1);
    verify(() => secureStorage.write(key: 'refresh_token', value: 'refresh-1'))
        .called(1);
  });

  test('clears all persisted tokens during logout', () async {
    when(() => secureStorage.deleteAll()).thenAnswer((_) async {});

    await storage.clear();

    verify(() => secureStorage.deleteAll()).called(1);
  });

  test('unchecked remember keeps tokens only in memory across refresh',
      () async {
    when(() => secureStorage.deleteAll()).thenAnswer((_) async {});
    when(() => secureStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    await storage.saveTokens(
        accessToken: 'access', refreshToken: 'refresh', persist: false);
    await storage.saveTokens(
        accessToken: 'rotated', refreshToken: 'rotated-refresh');
    expect(await storage.readAccessToken(), 'rotated');
    verifyNever(() => secureStorage.write(
        key: any(named: 'key'), value: any(named: 'value')));
    await storage.clear();
    expect(await storage.readAccessToken(), isNull);
  });
}
