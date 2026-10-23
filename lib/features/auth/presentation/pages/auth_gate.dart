import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/navigation/main_shell.dart';
import 'package:loqta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:loqta/features/auth/presentation/bloc/splash_bloc.dart';
import 'package:loqta/features/auth/presentation/pages/reset_password_page.dart';
import 'package:loqta/features/auth/presentation/pages/sign_in_page.dart';
import 'package:loqta/features/auth/presentation/pages/splash_page.dart';
import 'package:loqta/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:loqta/features/onboarding/presentation/pages/onboarding_page.dart';

/// The single routing decision point for the app.
///
/// Startup order:
///  1. [SplashBloc] holds the splash screen for a minimum time, so it is
///     actually seen instead of being skipped between two frames.
///  2. [AuthBloc] restores the persisted Supabase session, which the
///     repository confirms with the backend first, and [OnboardingBloc] reads
///     the local onboarding flag.
///  3. Splash is shown while *either* is still resolving, so sign-in can
///     never appear before session restoration finishes.
///  4. A password-recovery session routes to the Reset Password screen.
///  5. A valid authenticated session wins over onboarding and goes straight to
///     the existing home page.
///  6. Otherwise onboarding is shown if it has not been completed; if it has,
///     the existing sign-in page is shown.
///
/// The onboarding flag and the session are independent: signing out, or an
/// account being deleted in Supabase, never brings onboarding back, and
/// onboarding is never shown to a user who already has a valid session.
///
/// Because the gate returns a different root widget rather than pushing
/// routes, onboarding completing cannot produce duplicate or racing
/// navigation, and signing out returns to sign-in through the same path.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // The recovery link can arrive while an auth screen such as Forgot
    // Password is pushed above the gate. Rebuilding the gate's root alone would
    // leave that route covering the Reset Password screen, so return to the
    // root route when a recovery session starts.
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is PasswordRecovery && previous is! PasswordRecovery,
      listener: (context, state) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.popUntil((route) => route.isFirst);
        }
      },
      child: BlocBuilder<SplashBloc, SplashState>(
        builder: (context, splash) {
          // The splash is the app's first screen and stays on screen for a
          // minimum time, so the brand is seen before anything else.
          if (!splash.isFinished) {
            return const SplashPage();
          }
          return BlocBuilder<OnboardingBloc, OnboardingState>(
            builder: (context, onboarding) {
              return BlocBuilder<AuthBloc, AuthState>(
                builder: (context, auth) {
                  // Still restoring the Supabase session.
                  if (auth is AuthInitial || auth is AuthSessionRestoring) {
                    return const SplashPage();
                  }

                  // Password-recovery session: the user clicked the recovery
                  // link in the email. Route to Reset Password (no OTP).
                  if (auth is PasswordRecovery) {
                    return const ResetPasswordPage();
                  }

                  // A valid authenticated session always wins over onboarding.
                  if (auth is Authenticated) {
                    return const MainShell();
                  }

                  // No session. Wait for the onboarding flag before deciding.
                  if (onboarding.status == OnboardingStatus.loading) {
                    return const SplashPage();
                  }

                  if (onboarding.isShowingOnboarding) {
                    return const OnboardingPage();
                  }

                  return const SignInPage();
                },
              );
            },
          );
        },
      ),
    );
  }
}
