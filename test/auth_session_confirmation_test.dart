import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import 'package:loqta/features/auth/data/datasources/auth_data_source.dart';
import 'package:loqta/features/auth/data/repositories/auth_repository_impl.dart';

/// Data source fake that lets the test decide what the Auth server answers
/// when the repository asks whether the restored session is still good.
class _FakeAuthDataSource extends AuthDataSource {
  final _controller = StreamController<AuthState>.broadcast();

  /// The session the device has cached.
  User? currentSessionUser;

  /// Thrown by [getCurrentUser] instead of answering.
  Object? confirmationError;

  /// How many times the session was confirmed with the server.
  int confirmationCalls = 0;

  /// How many times the local session was cleared.
  int signOutCalls = 0;

  @override
  Stream<AuthState> get onAuthStateChanged => _controller.stream;

  @override
  User? get currentUser => currentSessionUser;

  @override
  Future<User> getCurrentUser() async {
    confirmationCalls++;
    final error = confirmationError;
    if (error != null) throw error;
    final user = currentSessionUser;
    if (user == null) {
      throw AuthException('User not found', statusCode: '403');
    }
    return user;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    currentSessionUser = null;
    _controller.add(AuthState(AuthChangeEvent.signedOut, null));
  }

  /// Emits the session Supabase restores at startup.
  void emitRestoredSession() {
    _controller.add(
      AuthState(
        AuthChangeEvent.initialSession,
        Session(
          accessToken: 'access',
          refreshToken: 'refresh',
          tokenType: 'bearer',
          user: currentSessionUser!,
        ),
      ),
    );
  }

  /// Emits the session a deliberate sign-in opens.
  void emitSignedIn() {
    _controller.add(
      AuthState(
        AuthChangeEvent.signedIn,
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

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({});
    dataSource = _FakeAuthDataSource();
    repository = AuthRepositoryImpl(dataSource);
    await repository.ready;
  }

  tearDown(() => dataSource.dispose());

  group('the session restored at startup', () {
    test('is reported as a sign-in when the account still exists', () async {
      await build();
      dataSource.currentSessionUser = _user('user-1', 'sara@example.com');

      final emitted = <Object?>[];
      final sub = repository.watchAuthState().listen(emitted.add);

      dataSource.emitRestoredSession();
      await Future<void>.delayed(Duration.zero);

      expect(emitted.single, isNotNull);
      expect(dataSource.confirmationCalls, 1);
      expect(dataSource.signOutCalls, 0);

      await sub.cancel();
    });

    test('is dropped and cleared when the account was deleted', () async {
      await build();
      dataSource.currentSessionUser = _user('user-1', 'sara@example.com');
      // Supabase answers the session check with "user not found".
      dataSource.confirmationError = AuthException(
        'User not found',
        statusCode: '403',
      );

      final emitted = <Object?>[];
      final sub = repository.watchAuthState().listen(emitted.add);

      dataSource.emitRestoredSession();
      await Future<void>.delayed(Duration.zero);

      // No user is reported, and the stale session is cleared from the device.
      expect(emitted, everyElement(isNull));
      expect(dataSource.signOutCalls, 1);
      expect(dataSource.currentSessionUser, isNull);

      await sub.cancel();
    });

    test('is dropped when the token is no longer accepted', () async {
      await build();
      dataSource.currentSessionUser = _user('user-1', 'sara@example.com');
      dataSource.confirmationError = AuthException(
        'Invalid Refresh Token',
        statusCode: '400',
      );

      final emitted = <Object?>[];
      final sub = repository.watchAuthState().listen(emitted.add);

      dataSource.emitRestoredSession();
      await Future<void>.delayed(Duration.zero);

      expect(emitted, everyElement(isNull));
      expect(dataSource.signOutCalls, 1);

      await sub.cancel();
    });

    test('is kept when the server cannot be reached', () async {
      await build();
      dataSource.currentSessionUser = _user('user-1', 'sara@example.com');
      // A network error says nothing about the account.
      dataSource.confirmationError = AuthRetryableFetchException(
        message: 'connection closed',
      );

      final emitted = <Object?>[];
      final sub = repository.watchAuthState().listen(emitted.add);

      dataSource.emitRestoredSession();
      await Future<void>.delayed(Duration.zero);

      // The local session is kept: a temporary network problem must not sign
      // the user out.
      expect(emitted.single, isNotNull);
      expect(dataSource.signOutCalls, 0);

      await sub.cancel();
    });

    test('is kept when the server is rate limiting the check', () async {
      await build();
      dataSource.currentSessionUser = _user('user-1', 'sara@example.com');
      dataSource.confirmationError = AuthApiException(
        'Too many requests',
        statusCode: '429',
      );

      final emitted = <Object?>[];
      final sub = repository.watchAuthState().listen(emitted.add);

      dataSource.emitRestoredSession();
      await Future<void>.delayed(Duration.zero);

      expect(emitted.single, isNotNull);
      expect(dataSource.signOutCalls, 0);

      await sub.cancel();
    });

    test('is not confirmed again for a later sign-in event', () async {
      await build();
      dataSource.currentSessionUser = _user('user-1', 'sara@example.com');

      final emitted = <Object?>[];
      final sub = repository.watchAuthState().listen(emitted.add);

      dataSource.emitRestoredSession();
      await Future<void>.delayed(Duration.zero);
      expect(dataSource.confirmationCalls, 1);

      // A deliberate sign-in is proof enough; the session is not checked a
      // second time.
      dataSource.emitSignedIn();
      await Future<void>.delayed(Duration.zero);

      expect(dataSource.confirmationCalls, 1);
      expect(emitted.length, 2);
      expect(emitted.last, isNotNull);

      await sub.cancel();
    });
  });
}
