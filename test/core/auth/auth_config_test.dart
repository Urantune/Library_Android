import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/core/config/auth_config.dart';

void main() {
  test('selects host loopback for desktop and host alias for Android emulator',
      () {
    const configured = String.fromEnvironment('AUTH_BASE_URL');
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(AuthConfig.baseUrl,
        configured.isEmpty ? 'http://127.0.0.1:8081' : configured);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(AuthConfig.baseUrl,
        configured.isEmpty ? 'http://10.0.2.2:8081' : configured);
  });
}
