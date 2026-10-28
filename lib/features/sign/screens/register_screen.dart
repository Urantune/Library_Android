import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_router.dart';
import '../constants/auth_constants.dart';
import '../controllers/auth_controller.dart';
import '../models/register_request.dart';
import '../utils/validators.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agreed = false;
  bool _termsError = false;

  @override
  void dispose() {
    for (final input in [_name, _email, _password, _confirm]) {
      input.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _form.currentState!.validate();
    setState(() => _termsError = !_agreed);
    if (!valid || !_agreed) return;
    final result = await ref.read(authControllerProvider.notifier).register(
        RegisterRequest(
            fullName: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text));
    if (!mounted || !result.success) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message)));
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return AuthLayout(
        cardHeight: 740,
        child: AutofillGroup(
            child: Form(
          key: _form,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const AuthHeader(
                title: AuthStrings.registerTitle,
                subtitle: AuthStrings.registerSubtitle),
            const SizedBox(height: 24),
            if (state.errorMessage != null) ...[
              AuthErrorBanner(message: state.errorMessage!),
              const SizedBox(height: 16),
            ],
            AuthTextField(
                label: AuthStrings.fullName,
                hint: AuthStrings.fullNameHint,
                controller: _name,
                validator: Validators.fullName,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                enabled: !state.isLoading),
            const SizedBox(height: 16),
            AuthTextField(
                label: AuthStrings.email,
                hint: 'ban@example.com',
                controller: _email,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                enabled: !state.isLoading),
            const SizedBox(height: 16),
            AuthTextField(
                label: AuthStrings.password,
                hint: 'Tối thiểu 8 ký tự',
                controller: _password,
                validator: Validators.password,
                isPassword: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                enabled: !state.isLoading),
            const SizedBox(height: 16),
            AuthTextField(
                label: AuthStrings.confirmPassword,
                hint: AuthStrings.confirmPasswordHint,
                controller: _confirm,
                validator: Validators.confirmPassword(() => _password.text),
                isPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                enabled: !state.isLoading),
            const SizedBox(height: 12),
            CheckboxListTile(
                value: _agreed,
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(AuthStrings.agreeTerms,
                    style: TextStyle(fontSize: 13)),
                onChanged: state.isLoading
                    ? null
                    : (value) => setState(() {
                          _agreed = value ?? false;
                          _termsError = false;
                        })),
            if (_termsError)
              const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(AuthStrings.mustAgreeTerms,
                      style: TextStyle(color: AuthColors.error, fontSize: 12))),
            const SizedBox(height: 18),
            PrimaryButton(
                label: AuthStrings.registerTitle,
                isLoading: state.isLoading,
                onPressed: _submit),
            const SizedBox(height: 16),
            Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(AuthStrings.haveAccount,
                      style: TextStyle(color: AuthColors.textSecondary)),
                  TextButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .clearError();
                              context.go(AppRoutes.login);
                            },
                      child: const Text(AuthStrings.goToLogin)),
                ]),
          ]),
        )));
  }
}
