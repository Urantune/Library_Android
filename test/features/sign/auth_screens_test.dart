import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_dungeo_library/app/app_router.dart';
import 'package:lore_dungeo_library/app/library_app.dart';
import 'package:lore_dungeo_library/features/sign/controllers/auth_controller.dart';
import 'fake_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!const bool.fromEnvironment('SAVE_AUTH_PREVIEW')) return;
    final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
    for (final entry in {
      'Roboto': ['roboto-regular.ttf', 'roboto-bold.ttf'],
      'MaterialIcons': ['materialicons-regular.otf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final filename in entry.value) {
        final file = File('${artifacts.path}/material_fonts/$filename');
        loader.addFont(
            file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)));
      }
      await loader.load();
    }
  });
  Future<ProviderContainer> open(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FakeAuthService();
    await tester.pumpWidget(ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(service)],
        child: const RepaintBoundary(
            key: ValueKey('auth-preview'), child: LibraryApp())));
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(LibraryApp)));
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('SAVE_AUTH_PREVIEW')) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('auth-preview')));
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/auth-preview');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('mobile login fits narrow screen and dashboard is guarded',
      (tester) async {
    final container = await open(tester, const Size(390, 844));
    expect(find.text('Đăng nhập'), findsWidgets);
    container.read(appRouterProvider).go(AppRoutes.dashboard);
    await tester.pumpAndSettle();
    expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        AppRoutes.login);
    expect(tester.takeException(), isNull);
    await capture(tester, 'login-mobile');
  });

  testWidgets('desktop shows library panel and no overflow', (tester) async {
    await open(tester, const Size(1200, 900));
    expect(find.text('Mỗi cuốn sách,\nmột chân trời mới.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, 'login-desktop');
  });

  testWidgets('register fits mobile and validates without sending request',
      (tester) async {
    final container = await open(tester, const Size(390, 844));
    await tester.tap(find.text('Đăng ký').last);
    await tester.pumpAndSettle();
    await capture(tester, 'register-mobile');
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Đăng ký'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng ký'));
    await tester.pumpAndSettle();
    final service = container.read(authServiceProvider) as FakeAuthService;
    expect(service.registrations, 0);
    expect(find.text('Họ tên cần 2–100 ký tự hợp lệ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login calls shared session and logout returns to guarded login',
      (tester) async {
    final container = await open(tester, const Size(1000, 1000));
    await tester.enterText(
        find.byType(TextFormField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');
    await tester
        .ensureVisible(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(
        container.read(authControllerProvider).user?.email, 'user@example.com');
    expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        AppRoutes.dashboard);
    await container.read(authControllerProvider.notifier).logout();
    await tester.pumpAndSettle();
    expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        AppRoutes.login);
  });

  testWidgets('login remains usable when keyboard reduces viewport',
      (tester) async {
    await open(tester, const Size(320, 600));
    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    expect(tester.takeException(), isNull);
  });
}
