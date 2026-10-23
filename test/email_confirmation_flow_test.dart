import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/loqta_button.dart';
import 'package:loqta/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:loqta/features/auth/domain/entities/auth_entities.dart';
import 'package:loqta/features/auth/domain/errors/auth_failure.dart';
import 'package:loqta/features/auth/domain/repositories/auth_repository.dart';
import 'package:loqta/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:loqta/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:loqta/features/auth/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:loqta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:loqta/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:loqta/features/auth/presentation/bloc/reset_password_bloc.dart';
import 'package:loqta/features/auth/presentation/bloc/splash_bloc.dart';
import 'package:loqta/features/auth/presentation/pages/auth_gate.dart';
import 'package:loqta/features/auth/presentation/pages/email_confirmation_pending_page.dart';
import 'package:loqta/features/auth/presentation/pages/sign_up_page.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';
import 'package:loqta/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:loqta/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:loqta/features/profile/domain/repositories/profile_repository.dart';

import 'support/fake_listing_repository.dart';
import 'support/fake_marketplace_repositories.dart';

/// Auth repository fake that mirrors the real repository's behaviour for the
/// confirmation-link flow:
///
///  * sign-up registers the account but never leaves a session, so the user is
///    not signed in until they sign in with their password;
///  * sign-in is refused while the address is unconfirmed;
///  * the confirmation callback confirms the address and drops the session it
///    would otherwise open.
///  * password recovery uses the new link-based flow (no OTP).
class _FakeAuthRepository implements AuthRepository {
  AuthUser? user;

  /// Whether the current account's email has been confirmed.
  bool emailConfirmed = true;

  /// Every sign-up attempt, so tests can assert the email/password use case
  /// was called with exactly what the form held.
  final List<
    ({String firstName, String lastName, String email, String password})
  >
  signUpAttempts = [];

  /// Every sign-in attempt.
  final List<({String email, String password})> signInAttempts = [];

  int signOutCalls = 0;

  /// When set, [signUpWithEmailAndPassword] fails with this message.
  String? signUpFailureMessage;

  /// When set, [signInWithEmailAndPassword] fails with this message.
  String? signInFailureMessage;

  final _controller = StreamController<Object?>.broadcast();

  static const newUser = AuthUser(
    id: 'user-1',
    email: 'sara@example.com',
    firstName: 'Sara',
  );

  @override
  AuthUser? get currentUser => user;

  @override
  Stream<Object?> watchAuthState() async* {
    yield user;
    yield* _controller.stream;
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInAttempts.add((email: email, password: password));
    final message = signInFailureMessage;
    if (message != null) throw AuthFailure(message);
    if (!emailConfirmed) {
      throw const AuthFailure(
        'Please verify your email address before signing in.',
      );
    }
    user = newUser;
    _controller.add(user);
    return newUser;
  }

  @override
  Future<AuthUser> signUpWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    signUpAttempts.add((
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    ));
    final message = signUpFailureMessage;
    if (message != null) throw AuthFailure(message);
    // Supabase confirms the email by link, so the account starts unconfirmed
    // and no session is created.
    emailConfirmed = false;
    user = null;
    return newUser;
  }

  /// Emails sent by "Forgot Password".
  final List<String> passwordResetEmails = [];

  /// Password resets completed (new link-based flow, no code).
  final List<({String newPassword})> passwordResets = [];

  /// When set, [resetPassword] fails with this message.
  String? resetFailureMessage;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    passwordResetEmails.add(email);
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {
    final message = resetFailureMessage;
    if (message != null) throw AuthFailure(message);
    passwordResets.add((newPassword: newPassword));
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {
    signOutCalls++;
    user = null;
    _controller.add(null);
  }

  /// Models the confirmation callback: Supabase confirms the address and, in
  /// the implicit flow, briefly hands back a session. The required flow drops
  /// that session so the user reaches Sign In and signs in manually.
  Future<void> confirmEmailAndDropSession() async {
    emailConfirmed = true;
    user = newUser;
    _controller.add(user);
    await signOut();
  }

  /// Models a password-recovery link click: the user clicked the recovery link
  /// in the email, and the app receives a PasswordRecoverySession.
  Future<void> simulateRecoveryLinkClick() async {
    user = newUser;
    _controller.add(PasswordRecoverySession(user!));
  }

  Future<void> dispose() => _controller.close();
}

class _FakeOnboardingRepository implements OnboardingRepository {
  @override
  Future<bool> isOnboardingCompleted() async => true;

  @override
  Future<void> completeOnboarding() async {}
}

/// Mirrors main.dart: repositories above `MaterialApp`, with the real
/// `AuthGate` as the root route, so sign-up and the confirmation-pending
/// screen sit on top of whatever the gate decides.
Widget _app(_FakeAuthRepository authRepository) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: authRepository),
      RepositoryProvider<ListingRepository>.value(
        value: FakeListingRepository(featured: featuredFixtureListings()),
      ),
      // The Profile destination is built when the test opens that tab.
      RepositoryProvider<ProfileRepository>.value(
        value: FakeProfileRepository(),
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authUserStream: authRepository.watchAuthState(),
            currentUser: () => authRepository.currentUser,
            signOutUseCase: SignOutUseCase(authRepository),
          )..add(const AuthStarted()),
        ),
        BlocProvider<OnboardingBloc>(
          create: (_) =>
              OnboardingBloc(repository: _FakeOnboardingRepository())
                ..add(const OnboardingStarted()),
        ),
        // The gate keeps the splash screen on screen for a minimum time.
        BlocProvider<SplashBloc>(
          create: (_) =>
              SplashBloc(minimumDuration: Duration.zero)
                ..add(const SplashStarted()),
        ),
      ],
      child: MaterialApp(theme: LoqtaTheme.light, home: const AuthGate()),
    ),
  );
}

void main() {
  late _FakeAuthRepository authRepository;

  setUp(() {
    authRepository = _FakeAuthRepository();
    authRepository.emailConfirmed = false;
  });
  tearDown(() => authRepository.dispose());

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  /// Fills the sign-up form from Sign In and submits it.
  Future<void> submitSignUp(
    WidgetTester tester, {
    String password = 'Passw0rd!',
  }) async {
    final createAccount = find.text('Create Account');
    await tester.ensureVisible(createAccount);
    await tester.pumpAndSettle();
    await tester.tap(createAccount);
    await tester.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(SignUpPage, skipOffstage: false),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), 'Sara');
    await tester.enterText(fields.at(1), 'Khoury');
    await tester.enterText(fields.at(2), 'sara@example.com');
    await tester.enterText(fields.at(3), password);
    await tester.enterText(fields.at(4), password);

    final submit = find.text('Create Account');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
  }

  testWidgets('valid sign-up calls the email/password use case and shows the '
      'confirmation-pending state', (tester) async {
    usePhoneViewport(tester);

    await tester.pumpWidget(_app(authRepository));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);

    await submitSignUp(tester);

    // 1. The email/password sign-up use case was called with the form values.
    expect(authRepository.signUpAttempts, [
      (
        firstName: 'Sara',
        lastName: 'Khoury',
        email: 'sara@example.com',
        password: 'Passw0rd!',
      ),
    ]);

    // 2. The confirmation-pending state is shown, for the right address.
    expect(find.byType(EmailConfirmationPendingPage), findsOneWidget);
    expect(find.text('Check your email'), findsOneWidget);
    expect(
      find.textContaining('We sent you a confirmation link'),
      findsOneWidget,
    );
    expect(find.text('sara@example.com'), findsOneWidget);

    // 3. No OTP entry screen, no code field, no resend countdown.
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Verify & Continue'), findsNothing);
    expect(find.text('Resend Code'), findsNothing);
    expect(find.textContaining('6-digit'), findsNothing);

    // The sign-up screen is gone; the pending screen replaced it.
    expect(find.byType(SignUpPage), findsNothing);
  });

  testWidgets('sign-up failure is reported and the form is kept', (
    tester,
  ) async {
    usePhoneViewport(tester);
    authRepository.signUpFailureMessage =
        'An account with this email already exists. Please sign in.';

    await tester.pumpWidget(_app(authRepository));
    await tester.pumpAndSettle();

    await submitSignUp(tester);

    // 4. The error surfaces through the existing BLoC failure state.
    expect(
      find.text('An account with this email already exists. Please sign in.'),
      findsOneWidget,
    );
    expect(find.byType(EmailConfirmationPendingPage), findsNothing);
    expect(find.byType(SignUpPage, skipOffstage: false), findsOneWidget);
  });

  testWidgets(
    'the confirmation callback returns the user to Sign In, not Home',
    (tester) async {
      usePhoneViewport(tester);

      await tester.pumpWidget(_app(authRepository));
      await tester.pumpAndSettle();
      await submitSignUp(tester);
      expect(find.byType(EmailConfirmationPendingPage), findsOneWidget);

      // 7. Supabase confirms the address and briefly opens a session; the app
      // drops it and routes back to Sign In rather than into the home screen.
      await authRepository.confirmEmailAndDropSession();
      await tester.pumpAndSettle();

      expect(find.byType(EmailConfirmationPendingPage), findsNothing);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Categories'), findsNothing);
    },
  );

  testWidgets('an unconfirmed account cannot sign in, and can once confirmed', (
    tester,
  ) async {
    usePhoneViewport(tester);

    await tester.pumpWidget(_app(authRepository));
    await tester.pumpAndSettle();

    // 6. Sign-in is refused while the address is unconfirmed.
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'sara@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Passw0rd!');
    await tester.ensureVisible(find.widgetWithText(LoqtaButton, 'Sign In'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(LoqtaButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please verify your email address before signing in.'),
      findsOneWidget,
    );
    expect(find.text('Categories'), findsNothing);
    expect(authRepository.signInAttempts.length, 1);

    // 5. Once confirmed, manual email/password sign-in reaches Home.
    await authRepository.confirmEmailAndDropSession();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'sara@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Passw0rd!');
    await tester.ensureVisible(find.widgetWithText(LoqtaButton, 'Sign In'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(LoqtaButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(authRepository.signInAttempts.last, (
      email: 'sara@example.com',
      password: 'Passw0rd!',
    ));
    expect(find.text('Welcome Back'), findsNothing);
    expect(find.text('Categories'), findsOneWidget);
  });

  testWidgets('sign-out still returns to Sign In', (tester) async {
    usePhoneViewport(tester);
    authRepository.emailConfirmed = true;

    await tester.pumpWidget(_app(authRepository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'sara@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Passw0rd!');
    await tester.ensureVisible(find.widgetWithText(LoqtaButton, 'Sign In'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(LoqtaButton, 'Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsOneWidget);

    // 9. Sign-out goes through the same AuthGate path as before. It lives on
    // the Profile destination of the shell.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Log Out'), findsOneWidget);

    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(authRepository.signOutCalls, greaterThanOrEqualTo(1));
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  group('password recovery uses the new link-based flow', () {
    test('Forgot Password still sends the reset email', () async {
      final bloc = ForgotPasswordBloc(
        SendPasswordResetEmailUseCase(authRepository),
      );
      addTearDown(bloc.close);

      bloc.add(const ResetEmailSubmitted('sara@example.com'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ForgotPasswordInProgress>(),
          isA<ForgotPasswordEmailSent>(),
        ]),
      );

      expect(authRepository.passwordResetEmails, ['sara@example.com']);
    });

    test('Reset Password uses the active recovery session (no code)', () async {
      final bloc = ResetPasswordBloc(ResetPasswordUseCase(authRepository));
      addTearDown(bloc.close);

      bloc.add(const ResetPasswordSubmitted(newPassword: 'N3wPassw0rd!'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ResetPasswordInProgress>(),
          isA<ResetPasswordSuccess>(),
        ]),
      );

      expect(authRepository.passwordResets, [(newPassword: 'N3wPassw0rd!')]);
    });

    test(
      'Reset Password reports a failure when the session is invalid',
      () async {
        authRepository.resetFailureMessage = 'The recovery link has expired.';

        final bloc = ResetPasswordBloc(ResetPasswordUseCase(authRepository));
        addTearDown(bloc.close);

        bloc.add(const ResetPasswordSubmitted(newPassword: 'N3wPassw0rd!'));
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ResetPasswordInProgress>(),
            isA<ResetPasswordFailure>().having(
              (state) => state.message,
              'message',
              'The recovery link has expired.',
            ),
          ]),
        );
      },
    );

    testWidgets('clicking the recovery link routes to Reset Password screen', (
      tester,
    ) async {
      usePhoneViewport(tester);

      await tester.pumpWidget(_app(authRepository));
      await tester.pumpAndSettle();
      expect(find.text('Welcome Back'), findsOneWidget);

      // Simulate the user clicking the recovery link in the email.
      await authRepository.simulateRecoveryLinkClick();
      await tester.pumpAndSettle();

      // Should show the Reset Password screen (no OTP field).
      expect(find.byType(EmailConfirmationPendingPage), findsNothing);
      expect(find.text('Reset Your Password'), findsOneWidget);
      expect(find.text('Recovery Code'), findsNothing);
      expect(find.text('Save New Password'), findsOneWidget);
    });

    testWidgets(
      'recovery link opened from Forgot Password replaces that route with '
      'Reset Password',
      (tester) async {
        usePhoneViewport(tester);

        await tester.pumpWidget(_app(authRepository));
        await tester.pumpAndSettle();

        // The email is sent from Forgot Password, which is pushed above the
        // AuthGate and therefore stays on top when the gate rebuilds.
        await tester.tap(find.text('Forgot Password?'));
        await tester.pumpAndSettle();
        expect(find.text('Forgot Your Password?'), findsOneWidget);

        await authRepository.simulateRecoveryLinkClick();
        await tester.pumpAndSettle();

        expect(find.text('Forgot Your Password?'), findsNothing);
        expect(find.text('Reset Your Password'), findsOneWidget);
        expect(find.text('Save New Password'), findsOneWidget);
      },
    );
  });
}
