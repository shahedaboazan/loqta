import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:loqta/features/auth/domain/entities/auth_entities.dart';
import 'package:loqta/features/auth/domain/repositories/auth_repository.dart';
import 'package:loqta/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:loqta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:loqta/features/auth/presentation/bloc/splash_bloc.dart';
import 'package:loqta/features/auth/presentation/pages/auth_gate.dart';
import 'package:loqta/features/auth/presentation/pages/splash_page.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';
import 'package:loqta/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:loqta/features/onboarding/presentation/bloc/onboarding_bloc.dart';

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

/// Auth repository fake that reports the session the way the real repository
/// does: a confirmed session is reported as a user, a rejected one is not.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user, this.session);

  /// The session cached on the device. It stays set for a rejected session,
  /// exactly like the real repository: the cached session outlives the
  /// account until the app clears it.
  AuthUser? user;

  final _Session session;

  bool signedOut = false;

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
  Future<void> signOut() async {
    signedOut = true;
    user = null;
  }
}

/// Onboarding repository fake that keeps the flag in memory, the way the
/// real one keeps it on the device.
class _FakeOnboardingRepository implements OnboardingRepository {
  _FakeOnboardingRepository(this.completed);

  bool completed;

  @override
  Future<bool> isOnboardingCompleted() async => completed;

  @override
  Future<void> completeOnboarding() async {
    completed = true;
  }
}

/// Builds the real `AuthGate` the way main.dart does.
Widget _app({
  required AuthUser? user,
  required bool onboardingCompleted,
  _Session session = _Session.none,
  Duration minimumSplashDuration = const Duration(milliseconds: 50),
  AuthRepository? authRepository,
  OnboardingRepository? onboardingRepository,
  Key? key,
}) {
  final auth = authRepository ?? _FakeAuthRepository(user, session);
  final onboarding =
      onboardingRepository ?? _FakeOnboardingRepository(onboardingCompleted);

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: auth),
      RepositoryProvider<ListingRepository>.value(
        value: FakeListingRepository(featured: featuredFixtureListings()),
      ),
    ],
    key: key,
    child: MaterialApp(
      theme: LoqtaTheme.light,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(
              authUserStream: auth.watchAuthState(),
              currentUser: () => auth.currentUser,
              signOutUseCase: SignOutUseCase(auth),
            )..add(const AuthStarted()),
          ),
          BlocProvider<OnboardingBloc>(
            create: (_) =>
                OnboardingBloc(repository: onboarding)
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

  group('the destination chosen at startup', () {
    testWidgets('onboarding is shown when it was never completed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(user: null, onboardingCompleted: false, session: _Session.none),
      );
      await tester.pumpAndSettle();

      expect(find.text('Find What You Need'), findsOneWidget);
      expect(find.text('Welcome Back'), findsNothing);
    });

    testWidgets('sign-in is shown when onboarding was completed before', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(user: null, onboardingCompleted: true, session: _Session.none),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Find What You Need'), findsNothing);
    });

    testWidgets('home is shown for a valid session', (tester) async {
      await tester.pumpWidget(
        _app(user: user, onboardingCompleted: false, session: _Session.valid),
      );
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Welcome Back'), findsNothing);
    });

    testWidgets('home is shown for a valid session even without onboarding', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(user: user, onboardingCompleted: true, session: _Session.valid),
      );
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
    });

    testWidgets('a rejected session never reaches home', (tester) async {
      // The account was deleted in Supabase, but the session is still cached
      // on the device. Home must not be reachable through it.
      await tester.pumpWidget(
        _app(
          user: user,
          onboardingCompleted: false,
          session: _Session.rejected,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsNothing);
      expect(find.text('Find What You Need'), findsOneWidget);
    });

    testWidgets('a rejected session lands on sign-in when onboarding is done', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(user: user, onboardingCompleted: true, session: _Session.rejected),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Categories'), findsNothing);
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
  });

  group('the splash screen', () {
    testWidgets('is the first screen the app draws', (tester) async {
      await tester.pumpWidget(
        _app(user: null, onboardingCompleted: false, session: _Session.none),
      );

      // The very first frame is the splash, before anything else is known.
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(AuthGate), findsOneWidget);
    });

    testWidgets('is not skipped when everything resolves immediately', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          user: null,
          onboardingCompleted: true,
          session: _Session.none,
          minimumSplashDuration: const Duration(seconds: 2),
        ),
      );

      // The session and the onboarding flag are already known, but the
      // splash stays on screen for its minimum time.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SplashPage), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SplashPage), findsOneWidget);

      // Only after the minimum duration does the app move on.
      await tester.pump(const Duration(milliseconds: 1200));
      // One more frame lets the state changes that were made in the same
      // frame reach the widget tree.
      await tester.pump();
      expect(find.byType(SplashPage), findsNothing);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('stays on screen while the session is still being restored', (
      tester,
    ) async {
      // A repository that never reports a session keeps the app in the
      // restoring state; the splash must stay up rather than the app
      // flashing the sign-in screen.
      final repository = _SilentAuthRepository();
      await tester.pumpWidget(
        _app(
          user: null,
          onboardingCompleted: true,
          authRepository: repository,
          minimumSplashDuration: const Duration(milliseconds: 50),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.text('Welcome Back'), findsNothing);
    });
  });

  group('onboarding completion', () {
    testWidgets('survives a sign-out', (tester) async {
      final onboardingRepository = _FakeOnboardingRepository(true);
      final authRepository = _FakeAuthRepository(user, _Session.valid);

      await tester.pumpWidget(
        _app(
          user: user,
          onboardingCompleted: true,
          session: _Session.valid,
          authRepository: authRepository,
          onboardingRepository: onboardingRepository,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Categories'), findsOneWidget);

      // Signing out must not bring onboarding back.
      final bloc = tester.element(find.byType(AuthGate)).read<AuthBloc>();
      bloc.add(const SignOutRequested());
      await tester.pumpAndSettle();

      expect(authRepository.signedOut, isTrue);
      expect(onboardingRepository.completed, isTrue);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Find What You Need'), findsNothing);
    });
  });
}

/// Auth repository that never reports a session, so the app keeps waiting
/// for the session to be restored.
class _SilentAuthRepository extends _FakeAuthRepository {
  _SilentAuthRepository() : super(null, _Session.none);

  @override
  Stream<Object?> watchAuthState() => const Stream<Object?>.empty();
}