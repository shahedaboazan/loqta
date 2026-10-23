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
import 'package:loqta/features/auth/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:loqta/features/auth/presentation/bloc/forgot_password_bloc.dart';

/// Forgot-password screen, rebuilt from
/// `design_drafts/screens/08_forgot_password.png`.
///
/// Copy matches the reference: a recovery *link* is emailed, which is what
/// Supabase's `resetPasswordForEmail` sends. The user clicks the link in the
/// email, which opens the app and navigates directly to the Reset Password
/// screen (handled by the auth gate). This screen only sends the email and
/// shows a confirmation message.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForgotPasswordBloc>(
      create: (_) => ForgotPasswordBloc(
        SendPasswordResetEmailUseCase(context.read<AuthRepository>()),
      ),
      child: const ForgotPasswordView(),
    );
  }
}

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ForgotPasswordBloc>().add(
        ResetEmailSubmitted(_emailController.text.trim()),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccess(String email) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'If an account exists for $email, a password reset link has been '
            'sent. Check your email and open the link to set a new password.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
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
            colors: [Color(0xFFFFFFFF), Color(0xFFF6FCF8)],
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
                      title: 'Forgot Password',
                      showBack: false,
                      trailing: SizedBox.shrink(),
                    ),
                    const Center(child: BrandLogo(size: 150)),
                    const Text(
                      'Forgot Your Password?',
                      textAlign: TextAlign.center,
                      style: LoqtaText.heading,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Enter your email address and we'll send you a link "
                      'to reset your password.',
                      textAlign: TextAlign.center,
                      style: LoqtaText.subtitle,
                    ),
                    const SizedBox(height: 26),
                    BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
                      listenWhen: (previous, current) =>
                          current is ForgotPasswordFailure ||
                          current is ForgotPasswordEmailSent,
                      listener: (context, state) {
                        if (state is ForgotPasswordFailure) {
                          _showError(state.message);
                        } else if (state is ForgotPasswordEmailSent) {
                          // The reset link has been sent. Show a confirmation
                          // message and stay on this screen. The user will
                          // click the link in the email, which opens the app
                          // and routes to the Reset Password screen via the
                          // auth gate.
                          _showSuccess(state.email);
                        }
                      },
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LoqtaTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hintText: 'Enter your registered email',
                              trailingIcon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              validator: AppValidators.email,
                              onFieldSubmitted: (_) => _submit(),
                              autofillHints: const [AutofillHints.email],
                            ),
                            const SizedBox(height: 20),
                            const InfoBanner(
                              icon: Icons.shield_outlined,
                              message:
                                  'For your safety, password recovery links '
                                  'expire within 30 minutes.',
                              compact: true,
                            ),
                            const SizedBox(height: 24),
                            BlocBuilder<
                              ForgotPasswordBloc,
                              ForgotPasswordState
                            >(
                              builder: (context, state) {
                                return LoqtaButton(
                                  label: 'Send Reset Email',
                                  onPressed: _submit,
                                  isLoading: state is ForgotPasswordInProgress,
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
}
