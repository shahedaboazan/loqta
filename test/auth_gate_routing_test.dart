import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:loqta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:loqta/features/auth/presentation/bloc/splash_bloc.dart';
import 'package:loqta/features/auth/presentation/pages/auth_gate.dart';
import 'package:loqta/features/auth/presentation/pages/sign_up_page.dart';
import 'package:loqta/features/auth/presentation/pages/splash_page.dart';
import 'package:loqta/features/auth/domain/entities/auth_entities.dart';
import 'package:loqta/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:loqta/features/auth/domain/repositories/auth_repository.dart';
import 'package:loqta/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:loqta/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';

import 'support/fake_listing_repository.dart';

/// The state of the session the fake repository reports at startup.
enum _Session {
  /// There is no session.
  none,

  /// A session Supabase confirmed: the user is signed in.
  valid,

  /// A session Supabase rejected, because the account was deleted. The
  /// repository cleared it, so no user is reported any more, even though the
  /// stale session is still cached on the device.
  rejected,

  /// A password-recovery session (user clicked the recovery link).
  passwordRecovery,
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user, this.session);

  /// The session cached on the device. It stays set for a rejected session,
  /// exactly like the real repository: the cached session outlives the
  /// account until the app clears it.
  AuthUser? user;

  final _Session session;

  @override
  AuthUser? get currentUser => user;

  @override
  Stream<Object?> watchAuthState() {
    final Object? reported = switch (session) {
      _Session.valid => user,
      _Session.passwordRecovery => PasswordRecoverySession(user!),
      _Session.none || _Session.rejected => null,
    };
    return Stream<Object?>.value(reported).asBroadcastStream();
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => user!;

  @override
  Future<AuthUser> signUpWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async => user!;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> resetPassword({required String newPassword}) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async => user = null;
}

class _FakeOnboardingRepository implements OnboardingRepository {
  _FakeOnboardingRepository(this.completed);

  bool completed;
  bool throwOnRead = false;

  @override
  Future<bool> isOnboardingCompleted() async {
    if (throwOnRead) throw Exception('storage unavailable');
    return completed;
  }

  @override
  Future<void> completeOnboarding() async {
    completed = true;
  }
}

/// Builds the real `AuthGate` wired to fake repositories, so these tests
/// exercise the actual startup routing logic.
Widget _app({
  required AuthUser? user,
  required bool onboardingCompleted,
  _Session session = _Session.none,
  bool throwOnOnboardingRead = false,
  Duration minimumSplashDuration = const Duration(milliseconds: 50),
  Key? key,
}) {
  final authRepository = _FakeAuthRepository(user, session);
  final onboardingRepository = _FakeOnboardingRepository(onboardingCompleted)
    ..throwOnRead = throwOnOnboardingRead;

  // Mirrors main.dart: the repository providers sit above MaterialApp so
  // pushed routes (sign-up, forgot password) can still resolve them. Home reads
  // ListingRepository when it builds FeaturedListingsBloc, so a session that
  // routes to Home needs one too.
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: authRepository),
      RepositoryProvider<ListingRepository>.value(
        value: FakeListingRepository(featured: featuredFixtureListings()),
      ),
    ],
    // A distinct key forces the element tree (and therefore the BlocProviders
    // inside it) to be rebuilt from scratch. Without it, pumping an identical
    // tree a second time updates in place and reuses the previous iteration's
    // already-completed OnboardingBloc.
    key: key,
    child: MaterialApp(
      theme: LoqtaTheme.light,
      home: MultiBlocProvider(
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
                OnboardingBloc(repository: onboardingRepository)
                  ..add(const OnboardingStarted()),
          ),
          BlocProvider<SplashBloc>(
            create: (_) =>
                SplashBloc(minimumDuration: minimumSplashDuration)
                  ..add(const SplashStarted()),
          ),
        ],
        child: const AuthGate(),
      ),
    ),
  );
}

void main() {
  const user = AuthUser(
    id: 'user-1',
    email: 'sara@example.com',
    firstName: 'Sara',
  );

  testWidgets('shows splash first, then onboarding for a new user', (
    tester,
  ) async {
    await tester.pumpWidget(_app(user: null, onboardingCompleted: false));

    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(SplashPage), findsNothing);
    expect(find.text('Find What You Need'), findsOneWidget);
  });

  testWidgets('shows sign-in when onboarding is already completed', (
    tester,
  ) async {
    await tester.pumpWidget(_app(user: null, onboardingCompleted: true));
    await tester.pumpAndSettle();

    expect(find.byType(SplashPage), findsNothing);
    expect(find.text('Find What You Need'), findsNothing);
    // The existing sign-in page is the single source of truth.
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('a valid session goes to home regardless of onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(user: user, onboardingCompleted: false, session: _Session.valid),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SplashPage), findsNothing);
    // The rebuilt Home screen from 10_home.png. 'Categories' sits in the first
    // sliver, which is built immediately; the featured grid below it is lazy.
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('For Sale'), findsWidgets);
    expect(find.text('Find What You Need'), findsNothing);
  });

  testWidgets('a password-recovery session routes to Reset Password', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(user: user, onboardingCompleted: false, session: _Session.passwordRecovery),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SplashPage), findsNothing);
    expect(find.text('Reset Your Password'), findsOneWidget);
    expect(find.text('Recovery Code'), findsNothing);
    expect(find.text('Save New Password'), findsOneWidget);
  });

  testWidgets('completing onboarding lands on the existing sign-in page', (
    tester,
  ) async {
    await tester.pumpWidget(_app(user: null, onboardingCompleted: false));
    await tester.pumpAndSettle();

    // Get Started on the third page.
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsNothing);
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('Skip marks onboarding complete and shows sign-in', (
    tester,
  ) async {
    await tester.pumpWidget(_app(user: null, onboardingCompleted: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('back navigation steps through onboarding pages', (tester) async {
    await tester.pumpWidget(_app(user: null, onboardingCompleted: false));
    await tester.pumpAndSettle();

    expect(find.text('Find What You Need'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Sell or Give'), findsOneWidget);

    // Drive the system back gesture directly: the onboarding pages expose no
    // back button, matching the reference designs.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Find What You Need'), findsOneWidget);
  });

  testWidgets('every onboarding page lays out on small and large screens', (
    tester,
  ) async {
    // Covers the supported mobile range from a small phone up to a large
    // one; each page must render without an overflow exception.
    for (final size in <Size>[
      const Size(320, 568),
      const Size(360, 640),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          user: null,
          onboardingCompleted: false,
          key: ValueKey('size-$size'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Find What You Need'), findsOneWidget, reason: '$size');

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'page 2 at $size');

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(
        find.text('Get Started'),
        findsOneWidget,
        reason: 'page 3 at $size',
      );
      expect(tester.takeException(), isNull, reason: 'page 3 at $size');
    }
  });

  testWidgets('sign-in stays reachable via the existing create-account link', (
    tester,
  ) async {
    await tester.pumpWidget(_app(user: null, onboardingCompleted: true));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);

    // The sign-in screen is taller than the 800x600 test viewport, so bring
    // the create-account link into view before tapping it.
    final createAccountLink = find.text('Create Account');
    await tester.ensureVisible(createAccountLink);
    await tester.pumpAndSettle();
    await tester.tap(createAccountLink);
    await tester.pumpAndSettle();

    expect(find.text('Create Your Account'), findsOneWidget);
    // The auth gate must still be alive beneath the pushed sign-up route.
    // skipOffstage: false because the covered route is offstage once
    // sign-up is pushed on top of it.
    expect(find.byType(AuthGate, skipOffstage: false), findsOneWidget);

    // The sign-in link sits below the fold on the 800x600 test viewport.
    // Scope to the sign-up route: the covered sign-in page underneath also
    // contains a "Sign In" link.
    final signInLink = find.descendant(
      of: find.byType(SignUpPage, skipOffstage: false),
      matching: find.text('Sign In'),
    );
    await tester.ensureVisible(signInLink);
    await tester.pumpAndSettle();
    await tester.tap(signInLink);
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.byType(AuthGate, skipOffstage: false), findsOneWidget);
  });
}