import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as legacy;
import '../../../app/app_router.dart';
import '../../../app/providers/navigation_provider.dart';
import '../constants/auth_constants.dart';
import '../controllers/auth_controller.dart';
import '../models/login_request.dart';
import '../utils/validators.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final navigation =
        legacy.Provider.of<NavigationProvider>(context, listen: false);
    final result = await ref.read(authControllerProvider.notifier).login(
        LoginRequest(email: _email.text.trim(), password: _password.text),
        remember: _remember);
    if (!result.success) return;
    navigation.goToDashboard();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chào ${result.user!.fullName}!')));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return AuthLayout(
        child: AutofillGroup(
            child: Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const AuthHeader(
            title: AuthStrings.loginTitle, subtitle: AuthStrings.loginSubtitle),
        const SizedBox(height: 28),
        if (state.errorMessage != null) ...[
          AuthErrorBanner(message: state.errorMessage!),
          const SizedBox(height: 18),
        ],
        AuthTextField(
            label: AuthStrings.email,
            hint: 'ban@example.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
            autofillHints: const [AutofillHints.username],
            onChanged: (_) =>
                ref.read(authControllerProvider.notifier).clearError(),
            enabled: !state.isLoading),
        const SizedBox(height: 18),
        AuthTextField(
            label: AuthStrings.password,
            hint: AuthStrings.passwordHint,
            controller: _password,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: Validators.loginPassword,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
            enabled: !state.isLoading),
        const SizedBox(height: 12),
        CheckboxListTile(
            value: _remember,
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(AuthStrings.rememberMe,
                style: TextStyle(fontSize: 13)),
            onChanged: state.isLoading
                ? null
                : (value) => setState(() => _remember = value ?? false)),
        const SizedBox(height: 18),
        PrimaryButton(
            label: AuthStrings.loginTitle,
            isLoading: state.isLoading,
            onPressed: _submit),
        const SizedBox(height: 18),
        Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(AuthStrings.noAccount,
                  style: TextStyle(color: AuthColors.textSecondary)),
              TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          ref
                              .read(authControllerProvider.notifier)
                              .clearError();
                          context.go(AppRoutes.register);
                        },
                  child: const Text(AuthStrings.goToRegister)),
            ]),
      ]),
    )));
  }
}
