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
import 'package:loqta/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:loqta/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:loqta/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:loqta/features/auth/presentation/pages/sign_up_page.dart';

/// Sign-in screen, rebuilt from `design_drafts/screens/05_sign_in.png`.
///
/// Note the app bar carries no back chevron: this screen is the root of the
/// unauthenticated flow.
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInBloc>(
      create: (_) => SignInBloc(SignInUseCase(context.read<AuthRepository>())),
      child: const SignInView(),
    );
  }
}

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<SignInBloc>().add(
        SignInSubmitted(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToSignUp() {
    // push, not pushReplacement: this screen is rendered by the AuthGate as
    // the root route, so replacing it would destroy the gate and leave nothing
    // to route back to after a successful sign-in.
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SignUpPage()));
  }

  void _goToForgotPassword() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ForgotPasswordPage()));
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
            colors: [Color(0xFFFFFFFF), Color(0xFFF7FDF9)],
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
                      title: 'Sign In',
                      showBack: false,
                      trailing: SizedBox.shrink(),
                    ),
                    const Center(child: BrandLogo(size: 150)),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: LoqtaText.heading,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to continue to Loqta',
                      textAlign: TextAlign.center,
                      style: LoqtaText.subtitle,
                    ),
                    const SizedBox(height: 26),
                    BlocListener<SignInBloc, SignInState>(
                      listenWhen: (previous, current) =>
                          current is SignInFailure || current is SignInSuccess,
                      listener: (context, state) {
                        if (state is SignInFailure) {
                          _showError(state.message);
                        } else if (state is SignInSuccess) {
                          // The AuthGate rebuilds this widget as HomePage once
                          // the session is active. Pop only if this screen was
                          // pushed on top of another route; popping the root
                          // route would close the app.
                          final navigator = Navigator.of(context);
                          if (navigator.canPop()) {
                            navigator.popUntil((route) => route.isFirst);
                          }
                        }
                      },
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // The reference groups the two fields, the
                            // recovery link and the primary action inside one
                            // white card.
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: LoqtaColors.surface,
                                borderRadius: BorderRadius.circular(
                                  LoqtaSpacing.radiusCard,
                                ),
                                border: Border.all(color: LoqtaColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  LoqtaTextField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    hintText: 'e.g. name@example.com',
                                    trailingIcon: Icons.mail_outline,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: AppValidators.email,
                                    autofillHints: const [AutofillHints.email],
                                  ),
                                  const SizedBox(height: 18),
                                  LoqtaTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hintText: 'Enter your password',
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    validator: AppValidators.passwordRequired,
                                    onFieldSubmitted: (_) => _submit(),
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _goToForgotPassword,
                                      style: TextButton.styleFrom(
                                        foregroundColor: LoqtaColors.primary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 8,
                                        ),
                                        minimumSize: const Size(48, 40),
                                        textStyle: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: LoqtaText.family,
                                        ),
                                      ),
                                      child: const Text('Forgot Password?'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  BlocBuilder<SignInBloc, SignInState>(
                                    builder: (context, state) {
                                      return LoqtaButton(
                                        label: 'Sign In',
                                        onPressed: _submit,
                                        isLoading: state is SignInProgress,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            InlineLinkRow(
                              prompt: "Don't have an account?",
                              linkLabel: 'Create Account',
                              onTap: _goToSignUp,
                            ),
                            const SoftDivider(verticalPadding: 20),
                            const IconCaption(
                              icon: Icons.verified_user_outlined,
                              label:
                                  'Safe & Verified Syria Pre-Owned '
                                  'Marketplace',
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
