import 'package:go_router/go_router.dart';

import '../features/sign/screens/login_screen.dart';
import '../features/sign/screens/register_screen.dart';
import 'screens/dashboard_page.dart';

/// Tên các đường dẫn, dùng chung để tránh gõ sai chuỗi.
class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardPage(),
    ),
  ],
);