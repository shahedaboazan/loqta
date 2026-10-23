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
import 'package:loqta/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:loqta/features/auth/presentation/bloc/sign_up_bloc.dart';
import 'package:loqta/features/auth/presentation/pages/email_confirmation_pending_page.dart';
import 'package:loqta/features/auth/presentation/pages/sign_in_page.dart';

/// Sign-up screen, rebuilt from `design_drafts/screens/06_sign_up.png`.
///
/// The reference stacks the five fields in a single column with their icons on
/// the trailing edge, which is what this screen renders.
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignUpBloc>(
      create: (_) => SignUpBloc(SignUpUseCase(context.read<AuthRepository>())),
      child: const SignUpView(),
    );
  }
}

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<SignUpBloc>().add(
        SignUpSubmitted(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
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

  void _goToSignIn() {
    final navigator = Navigator.of(context);
    // Sign-up is always pushed on top of the AuthGate's sign-in screen, so pop
    // back to it rather than replacing the route; replacing would drop the
    // gate from the widget tree.
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const SignInPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
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
                      title: 'Sign Up',
                      showBack: false,
                      trailing: SizedBox.shrink(),
                    ),
                    const Center(child: BrandLogo(size: 150)),
                    const Text(
                      'Create Your Account',
                      textAlign: TextAlign.center,
                      style: LoqtaText.heading,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Join Loqta to buy, sell, or donate pre-owned items '
                      'in your community.',
                      textAlign: TextAlign.center,
                      style: LoqtaText.subtitle,
                    ),
                    const SizedBox(height: 24),
                    BlocListener<SignUpBloc, SignUpState>(
                      listenWhen: (previous, current) =>
                          current is SignUpFailure || current is SignUpSuccess,
                      listener: (context, state) {
                        if (state is SignUpFailure) {
                          _showError(state.message);
                        }
                      },
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LoqtaTextField(
                              controller: _firstNameController,
                              label: 'First Name',
                              hintText: 'e.g. Sami',
                              trailingIcon: Icons.work_outline,
                              textInputAction: TextInputAction.next,
                              validator: (value) =>
                                  AppValidators.name(value, 'First Name'),
                              autofillHints: const [AutofillHints.givenName],
                            ),
                            const SizedBox(height: 16),
                            LoqtaTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              hintText: 'e.g. Al-Ahmad',
                              trailingIcon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              validator: (value) =>
                                  AppValidators.name(value, 'Last Name'),
                              autofillHints: const [AutofillHints.familyName],
                            ),
                            const SizedBox(height: 16),
                            LoqtaTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hintText: 'name@example.com',
                              trailingIcon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: AppValidators.email,
                              autofillHints: const [AutofillHints.email],
                            ),
                            const SizedBox(height: 16),
                            LoqtaTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hintText: 'At least 8 characters',
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              validator: AppValidators.password,
                              helper:
                                  'Use 8+ characters with a mix of '
                                  'letters, numbers and symbols.',
                              autofillHints: const [AutofillHints.newPassword],
                            ),
                            const SizedBox(height: 16),
                            LoqtaTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              hintText: 'Repeat password',
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              validator: (value) =>
                                  AppValidators.confirmPassword(
                                    value,
                                    _passwordController.text,
                                  ),
                              onFieldSubmitted: (_) => _submit(),
                              autofillHints: const [AutofillHints.newPassword],
                            ),
                            const SizedBox(height: 22),
                            const InfoBanner(
                              icon: Icons.verified_user_outlined,
                              message:
                                  'A confirmation link will be sent to '
                                  'confirm your email after signing up.',
                            ),
                            const SizedBox(height: 22),
                            BlocBuilder<SignUpBloc, SignUpState>(
                              builder: (context, state) {
                                return LoqtaButton(
                                  label: 'Create Account',
                                  onPressed: _submit,
                                  isLoading: state is SignUpInProgress,
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            InlineLinkRow(
                              prompt: 'Already have an account?',
                              linkLabel: 'Sign In',
                              onTap: _goToSignIn,
                            ),
                            // Registration succeeded: Supabase has emailed a confirmation link and no
                            // session exists, so the user is told to confirm and
                            // then sign in. Never navigate to the authenticated
                            // home from here.
                            BlocListener<SignUpBloc, SignUpState>(
                              listenWhen: (previous, current) =>
                                  current is SignUpSuccess,
                              listener: (context, state) {
                                final success = state as SignUpSuccess;
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        EmailConfirmationPendingPage(
                                          email: success.email,
                                        ),
                                  ),
                                );
                              },
                              child: const SizedBox.shrink(),
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
