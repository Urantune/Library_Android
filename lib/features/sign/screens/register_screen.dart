import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../app/providers/navigation_provider.dart';
import '../constants/auth_constants.dart';
import '../controllers/auth_controller.dart';
import '../models/register_request.dart';
import '../utils/validators.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _agreeTerms = false;
  String? _termsError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    if (!_agreeTerms) {
      setState(() => _termsError = AuthStrings.mustAgreeTerms);
    }
    if (!formOk || !_agreeTerms) return;

    final controller = context.read<AuthController>();
    final response = await controller.register(
      RegisterRequest(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      ),
    );
    if (!mounted || !response.success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message)),
    );
    _goToLogin();
  }

    void _goToLogin() => context.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();

    return AuthLayout(
      cardHeight: 720,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: AuthStrings.registerTitle,
              subtitle: AuthStrings.registerSubtitle,
            ),
            const SizedBox(height: 22),
            if (controller.errorMessage != null) ...[
              AuthErrorBanner(message: controller.errorMessage!),
              const SizedBox(height: 14),
            ],
            AuthTextField(
              label: AuthStrings.fullName,
              hint: AuthStrings.fullNameHint,
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              validator: Validators.fullName,
              enabled: !controller.isLoading,
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            AuthTextField(
              label: AuthStrings.password,
              hint: AuthStrings.passwordHint,
              controller: _passwordCtrl,
              isPassword: true,
              textInputAction: TextInputAction.next,
              validator: Validators.password,
              enabled: !controller.isLoading,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              label: AuthStrings.confirmPassword,
              hint: AuthStrings.confirmPasswordHint,
              controller: _confirmCtrl,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: Validators.confirmPassword(() => _passwordCtrl.text),
              onSubmitted: (_) => _submit(),
              enabled: !controller.isLoading,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreeTerms,
                    activeColor: AuthColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (v) => setState(() {
                      _agreeTerms = v ?? false;
                      if (_agreeTerms) _termsError = null;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    AuthStrings.agreeTerms,
                    style: TextStyle(fontSize: 13, color: AuthColors.textPrimary),
                  ),
                ),
              ],
            ),
            if (_termsError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _termsError!,
                  style: const TextStyle(fontSize: 12, color: AuthColors.error),
                ),
              ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: AuthStrings.registerTitle,
              isLoading: controller.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  AuthStrings.haveAccount,
                  style: TextStyle(fontSize: 13, color: AuthColors.textSecondary),
                ),
                InkWell(
                  onTap: controller.isLoading ? null : _goToLogin,
                  child: const Text(
                    AuthStrings.goToLogin,
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
