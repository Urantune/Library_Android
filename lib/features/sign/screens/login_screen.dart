import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../constants/auth_constants.dart';
import '../controllers/auth_controller.dart';
import '../models/login_request.dart';
import '../utils/validators.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';
import '../../../app/app_router.dart';
import '../../../app/providers/navigation_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = true; // Chỉ hiển thị, chưa lưu thật.

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = context.read<AuthController>();
    final response = await controller.login(
      LoginRequest(email: _emailCtrl.text.trim(), password: _passwordCtrl.text),
    );
        if (!mounted || !response.success) return;

    // Đưa dashboard về trang chủ, rồi chuyển sang dashboard.
    context.read<NavigationProvider>().goToDashboard();
    context.go(AppRoutes.dashboard);
  }

    void _goToRegister() => context.go(AppRoutes.register);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();

    return AuthLayout(
      cardHeight: 620,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: AuthStrings.loginTitle,
              subtitle: AuthStrings.loginSubtitle,
            ),
            const SizedBox(height: 28),
            if (controller.errorMessage != null) ...[
              AuthErrorBanner(message: controller.errorMessage!),
              const SizedBox(height: 16),
            ],
            AuthTextField(
              label: AuthStrings.email,
              hint: AuthStrings.emailHint,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              onChanged: (_) => controller.clearError(),
              enabled: !controller.isLoading,
            ),
            const SizedBox(height: 18),
            AuthTextField(
              label: AuthStrings.password,
              hint: AuthStrings.passwordHint,
              controller: _passwordCtrl,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: Validators.password,
              onChanged: (_) => controller.clearError(),
              onSubmitted: (_) => _submit(),
              enabled: !controller.isLoading,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: AuthColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  AuthStrings.rememberMe,
                  style: TextStyle(fontSize: 13, color: AuthColors.textPrimary),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Chưa có chức năng.
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    AuthStrings.forgotPassword,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AuthColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: AuthStrings.loginTitle,
              isLoading: controller.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  AuthStrings.noAccount,
                  style: TextStyle(fontSize: 13, color: AuthColors.textSecondary),
                ),
                InkWell(
                  onTap: controller.isLoading ? null : _goToRegister,
                  child: const Text(
                    AuthStrings.goToRegister,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AuthColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
