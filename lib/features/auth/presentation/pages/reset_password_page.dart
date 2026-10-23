import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/utils/validators.dart';
import 'package:loqta/core/widgets/brand_logo.dart';
import 'package:loqta/core/widgets/info_banner.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/core/widgets/loqta_button.dart';
import 'package:loqta/core/widgets/loqta_text_field.dart';
import 'package:loqta/features/auth/domain/repositories/auth_repository.dart';
import 'package:loqta/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:loqta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:loqta/features/auth/presentation/bloc/reset_password_bloc.dart';

/// Reset-password screen for the password-recovery link flow.
///
/// The user arrives here after clicking the recovery link in the email.
/// The Supabase session is already active (passwordRecovery event), so no
/// OTP entry is required. The screen only asks for the new password and
/// confirmation.
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ResetPasswordBloc>(
      create: (_) => ResetPasswordBloc(
        ResetPasswordUseCase(context.read<AuthRepository>()),
      ),
      child: const ResetPasswordView(),
    );
  }
}

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ResetPasswordBloc>().add(
        ResetPasswordSubmitted(newPassword: _passwordController.text),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LoqtaSpacing.radiusCard),
        ),
        title: const Text('Password updated'),
        content: const Text(
          'Your password has been changed. You can now sign in with your '
          'new password.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    // The recovery session signed the user in; sign out so the gate returns to
    // Sign In, then drop back to the gate's root route.
    context.read<AuthBloc>().add(const SignOutRequested());
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF5FBF7)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                LoqtaSpacing.gutter,
                0,
                LoqtaSpacing.gutter,
                24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: LoqtaSpacing.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const LoqtaAppBar(
                      title: 'Reset Password',
                      showBack: false,
                      trailing: SizedBox.shrink(),
                    ),
                    const Center(child: BrandLogo(size: 150)),
                    const Center(
                      child: BrandPill(
                        label: 'Loqta Secure Guard',
                        icon: Icons.verified_user_outlined,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Reset Your Password',
                      textAlign: TextAlign.center,
                      style: LoqtaText.heading,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Create a new password for your Loqta account.',
                      textAlign: TextAlign.center,
                      style: LoqtaText.subtitle,
                    ),
                    const SizedBox(height: 26),
                    BlocListener<ResetPasswordBloc, ResetPasswordState>(
                      listenWhen: (previous, current) =>
                          current is ResetPasswordFailure ||
                          current is ResetPasswordSuccess,
                      listener: (context, state) {
                        if (state is ResetPasswordFailure) {
                          _showError(state.message);
                        } else if (state is ResetPasswordSuccess) {
                          _showSuccessDialog();
                        }
                      },
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // The design pairs the label with a muted length
                            // hint on the trailing edge.
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'New Password',
                                  style: LoqtaText.fieldLabel,
                                ),
                                Text('Min. 8 chars', style: LoqtaText.caption),
                              ],
                            ),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscureNew,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: AppValidators.password,
                              onChanged: (_) {
                                // Keeps the "match" helper in step with the
                                // confirm field while typing.
                                setState(() {});
                              },
                              style: _fieldStyle,
                              decoration: InputDecoration(
                                hintText: 'Min. 8 characters',
                                hintStyle: LoqtaText.fieldHint,
                                suffixIconConstraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscureNew = !_obscureNew,
                                  ),
                                  icon: Icon(
                                    _obscureNew
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 19,
                                    color: LoqtaColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            _HelperLine(text: 'Must be at least 8 characters'),
                            const SizedBox(height: 18),
                            LoqtaTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              hintText: 'Re-enter new password',
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setState(() {}),
                              onFieldSubmitted: (_) => _submit(),
                              autofillHints: const [AutofillHints.newPassword],
                              validator: (_) => AppValidators.confirmPassword(
                                _confirmPasswordController.text,
                                _passwordController.text,
                              ),
                              helperWidget: _HelperLine(
                                text: 'Passwords must match',
                                error:
                                    _confirmPasswordController
                                        .text
                                        .isNotEmpty &&
                                    _confirmPasswordController.text !=
                                        _passwordController.text,
                              ),
                            ),
                            const SizedBox(height: 22),
                            const InfoBanner(
                              icon: Icons.vpn_key_outlined,
                              message:
                                  'Tip: Use a mix of uppercase letters, '
                                  'numbers, and symbols to keep your Syrian '
                                  'marketplace account secure.',
                            ),
                            const SizedBox(height: 24),
                            BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
                              builder: (context, state) {
                                return LoqtaButton(
                                  label: 'Save New Password',
                                  onPressed: _submit,
                                  isLoading: state is ResetPasswordInProgress,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _fieldStyle = TextStyle(
    color: LoqtaColors.textPrimary,
    fontSize: 14.5,
    fontFamily: LoqtaText.family,
  );

  bool _obscureNew = true;
}

/// The small muted "must be / must match" line the designs place under a field.
class _HelperLine extends StatelessWidget {
  const _HelperLine({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          error ? Icons.error_outline : Icons.check_circle_outline,
          size: 13,
          color: error ? LoqtaColors.error : LoqtaColors.textTertiary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: LoqtaText.caption.copyWith(
              color: error ? LoqtaColors.error : LoqtaColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
