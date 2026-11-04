import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static final TokenStorage shared = TokenStorage();
  TokenStorage([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  String? _access;
  String? _refresh;
  bool _persist = true;

  Future<String?> readAccessToken() async =>
      _access ?? await _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() async =>
      _refresh ?? await _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens(
      {required String accessToken,
      required String refreshToken,
      bool? persist}) async {
    if (persist != null) _persist = persist;
    if (_persist) {
      try {
        await _storage.write(key: _accessTokenKey, value: accessToken);
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      } catch (_) {
        await clear();
        rethrow;
      }
    } else {
      await _storage.deleteAll();
    }
    _access = accessToken;
    _refresh = refreshToken;
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    await _storage.deleteAll();
  }
}
