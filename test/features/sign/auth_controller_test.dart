import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/features/sign/controllers/auth_controller.dart';
import 'package:lore_dungeo_library/features/sign/models/auth_response.dart';
import 'package:lore_dungeo_library/features/sign/models/login_request.dart';
import 'fake_auth_service.dart';

void main() {
  test('restores persisted user and logout invalidates app session', () async {
    final service = FakeAuthService()..restored = FakeAuthService.reader;
    final container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(service)]);
    addTearDown(container.dispose);
    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(authControllerProvider).user?.id, 'u1');
    await container.read(authControllerProvider.notifier).logout();
    expect(container.read(authControllerProvider).user, isNull);
    expect(service.logouts, 1);
  });

  test('double submit calls transport once and clears loading after completion',
      () async {
    final service = FakeAuthService();
    final pending = Completer<AuthResponse>();
    service.pending = pending.future;
    final container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(service)]);
    addTearDown(container.dispose);
    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
    final controller = container.read(authControllerProvider.notifier);
    const input =
        LoginRequest(email: 'user@example.com', password: 'Password123!');
    final first = controller.login(input, remember: false);
    final second = await controller.login(input);
    expect(second.success, false);
    expect(service.logins, 1);
    pending.complete(const AuthResponse.success(user: FakeAuthService.reader));
    await first;
    expect(container.read(authControllerProvider).isLoading, false);
    expect(container.read(authControllerProvider).user?.id, 'u1');
    expect(service.remember, false);
  });
}
