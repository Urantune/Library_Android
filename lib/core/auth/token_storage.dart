import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  const TokenStorage([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }
  Future<void> clear() => _storage.deleteAll();
}
