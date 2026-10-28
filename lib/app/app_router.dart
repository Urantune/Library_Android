import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/sign/controllers/auth_controller.dart';
import '../features/sign/screens/login_screen.dart';
import '../features/sign/screens/register_screen.dart';
import 'screens/dashboard_page.dart';

class AppRoutes {
  AppRoutes._();
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const session = '/session';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (previous, next) {
    if (previous?.user != next.user ||
        previous?.isRestoring != next.isRestoring) {
      refresh.value++;
    }
  });
  final router = GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refresh,
    redirect: (context, route) {
      final session = ref.read(authControllerProvider);
      final path = route.uri.path;
      if (session.isRestoring) {
        return path == AppRoutes.session ? null : AppRoutes.session;
      }
      if (session.user == null) {
        return path == AppRoutes.login || path == AppRoutes.register
            ? null
            : AppRoutes.login;
      }
      return path == AppRoutes.login ||
              path == AppRoutes.register ||
              path == AppRoutes.session
          ? AppRoutes.dashboard
          : null;
    },
    routes: [
      GoRoute(
          path: AppRoutes.session,
          builder: (_, __) =>
              const Scaffold(body: Center(child: CircularProgressIndicator()))),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: AppRoutes.dashboard, builder: (_, __) => const DashboardPage()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
