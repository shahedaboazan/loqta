import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import 'package:loqta/features/auth/data/datasources/auth_data_source.dart';
import 'package:loqta/features/auth/data/repositories/auth_repository_impl.dart';

/// Subclass of the real data source so the repository can be exercised without
/// a Supabase client. `AuthDataSource` reaches the SDK only through its private
/// `_auth` getter, so overriding every method the repository uses is enough.
class _FakeAuthDataSource extends AuthDataSource {
  final _controller = StreamController<AuthState>.broadcast();

  /// Session the fake Supabase client currently holds.
  User? currentSessionUser;

  int signOutCalls = 0;
  int signUpCalls = 0;

  /// Email+password of the last manual sign-in.
  ({String email, String password})? lastSignIn;

  /// Whether the next manual sign-in should succeed.
  bool signInSucceeds = true;

  @override
  Stream<AuthState> get onAuthStateChanged => _controller.stream;

  @override
  User? get currentUser => currentSessionUser;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    currentSessionUser = null;
    _controller.add(AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
    String? emailRedirectTo = kAuthEmailRedirectTo,
  }) async {
    signUpCalls++;
    lastSignUpRedirectTo = emailRedirectTo;
    final user = _user('user-1', email);
    // Supabase returns no session while email confirmation is required.
    return AuthResponse(session: null, user: user);
  }

  String? lastSignUpRedirectTo;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    lastSignIn = (email: email, password: password);
    final user = _user('user-1', email);
    if (signInSucceeds) currentSessionUser = user;
    return AuthResponse(user: user, session: null);
  }

  /// Emits the session Supabase opens when an emailed link is followed.
  ///
  /// `exchangeCodeForSession` reports [AuthChangeEvent.passwordRecovery] when
  /// the stored PKCE verifier carries the recovery event name, and
  /// [AuthChangeEvent.signedIn] otherwise (the signup-confirmation case).
  void emitLinkSession(String email, AuthChangeEvent event) {
    currentSessionUser = _user('user-1', email);
    _controller.add(
      AuthState(
        event,
        Session(
          accessToken: 'access',
          refreshToken: 'refresh',
          tokenType: 'bearer',
          user: currentSessionUser!,
        ),
      ),
    );
  }

  Future<void> dispose() => _controller.close();
}

const _key = AuthRepositoryImpl.pendingEmailKey;

/// Minimal [User] for the guard tests: only email is read.
User _user(String id, String email) => User(
  id: id,
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
  email: email,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthDataSource dataSource;
  late AuthRepositoryImpl repository;

  Future<void> build({String? pendingEmail}) async {
    SharedPreferences.setMockInitialValues(
      pendingEmail == null ? {} : {_key: pendingEmail},
    );
    dataSource = _FakeAuthDataSource();
    repository = AuthRepositoryImpl(dataSource);
    await repository.ready;
  }

  tearDown(() => dataSource.dispose());

  group('the signup-confirmation guard', () {
    test('drops the session opened by the confirmation link', () async {
      await build(pendingEmail: 'sara@example.com');
      final emitted = <Object?>[];
      final sub = repository.watchAuthState().listen(emitted.add);

      // Exactly what exchangeCodeForSession emits for a signup link.
      dataSource.emitLinkSession('sara@example.com', AuthChangeEvent.signedIn);
      await Future<void>.delayed(Duration.zero);

      // The confirmation session is never surfaced: the guard emits null for
      // the signedIn event, and the sign-out it triggers emits a second null.
      expect(emitted, isNotEmpty);
      expect(emitted, everyElement(isNull));
      expect(dataSource.signOutCalls, 1);

      final preferences = await SharedPreferences.getInstance();
      // The marker is cleared *before* the sign-out, so a misfire can never
      // lock the user out of signing in.
      expect(preferences.getString(_key), isNull);

      await sub.cancel();
    });

    test('leaves a session for a different account alone', () async {
      await build(pendingEmail: 'someone.else@example.com');
      final emitted = <Object?>[];
      final sub = repository.watchAuthState().listen(emitted.add);

      dataSource.emitLinkSession('sara@example.com', AuthChangeEvent.signedIn);
      await Future<void>.delayed(Duration.zero);

      expect(emitted.single, isNotNull);
      expect(dataSource.signOutCalls, 0);

      await sub.cancel();
    });

    test('never reports a confirmed account as signed in', () async {
      await build(pendingEmail: 'sara@example.com');
      dataSource.currentSessionUser = _user('user-1', 'sara@example.com');

      expect(repository.currentUser, isNull);
    });

    test('reports an unrelated session as signed in', () async {
      await build(pendingEmail: 'sara@example.com');
      dataSource.currentSessionUser = _user('user-2', 'omar@example.com');

      expect(repository.currentUser, isNotNull);
    });
  });

  group('password recovery is untouched', () {
    test('keeps the session opened by a recovery link', () async {
      // Even when the address awaiting signup confirmation is the one being
      // recovered, the recovery event must not be treated as a confirmation.
      await build(pendingEmail: 'sara@example.com');
      final emitted = <Object?>[];
      final sub = repository.watchAuthState().listen(emitted.add);

      dataSource.emitLinkSession(
        'sara@example.com',
        AuthChangeEvent.passwordRecovery,
      );
      await Future<void>.delayed(Duration.zero);

      expect(emitted.single, isNotNull);
      expect(dataSource.signOutCalls, 0);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(_key), 'sara@example.com');

      await sub.cancel();
    });
  });

  group('session restoration is untouched', () {
    test('a restored session is emitted, not dropped', () async {
      await build(pendingEmail: 'sara@example.com');
      final emitted = <Object?>[];
      final sub = repository.watchAuthState().listen(emitted.add);

      // Startup restoration arrives as an initial event, never as signedIn.
      dataSource.emitLinkSession(
        'sara@example.com',
        AuthChangeEvent.initialSession,
      );
      await Future<void>.delayed(Duration.zero);

      expect(emitted.single, isNotNull);
      expect(dataSource.signOutCalls, 0);

      await sub.cancel();
    });
  });

  group('a deliberate sign-in is never mistaken for the callback', () {
    test('clears a stale marker and keeps the session', () async {
      await build(pendingEmail: 'sara@example.com');
      final emitted = <Object?>[];
      final sub = repository.watchAuthState().listen(emitted.add);

      // The user never opened the link and signs in by typing their password.
      await repository.signInWithEmailAndPassword(
        email: 'sara@example.com',
        password: 'Passw0rd!',
      );
      dataSource.emitLinkSession('sara@example.com', AuthChangeEvent.signedIn);
      await Future<void>.delayed(Duration.zero);

      expect(emitted.single, isNotNull);
      expect(dataSource.signOutCalls, 0);
      expect(dataSource.lastSignIn, (
        email: 'sara@example.com',
        password: 'Passw0rd!',
      ));

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(_key), isNull);

      // The marker is gone, so the guard cannot fire again and trap the user.
      dataSource.emitLinkSession('sara@example.com', AuthChangeEvent.signedIn);
      await Future<void>.delayed(Duration.zero);
      expect(dataSource.signOutCalls, 0);

      await sub.cancel();
    });
  });

  group('signup wiring', () {
    test('sends the configured confirmation redirect', () async {
      await build();

      await repository.signUpWithEmailAndPassword(
        firstName: 'Sara',
        lastName: 'Khoury',
        email: 'sara@example.com',
        password: 'Passw0rd!',
      );

      expect(dataSource.signUpCalls, 1);
      expect(dataSource.lastSignUpRedirectTo, 'loqta://auth/confirm');
    });

    test('records the address only after a successful signup', () async {
      await build();

      await repository.signUpWithEmailAndPassword(
        firstName: 'Sara',
        lastName: 'Khoury',
        email: 'sara@example.com',
        password: 'Passw0rd!',
      );

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(_key), 'sara@example.com');
    });
  });
}
