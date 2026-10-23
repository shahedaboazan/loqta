import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:loqta/features/auth/data/datasources/auth_data_source.dart';
import 'package:loqta/features/auth/data/models/auth_user_model.dart';
import 'package:loqta/features/auth/data/repositories/auth_error_mapper.dart';
import 'package:loqta/features/auth/domain/entities/auth_entities.dart';
import 'package:loqta/features/auth/domain/errors/auth_failure.dart';
import 'package:loqta/features/auth/domain/repositories/auth_repository.dart';

/// How long the app waits for Supabase to confirm the restored session
/// before it gives up and keeps the locally stored session.
///
/// A slow or unreachable network must not leave the user staring at the
/// splash screen, so the check is bounded.
const Duration kSessionConfirmationTimeout = Duration(seconds: 10);

/// The outcome of asking Supabase whether the restored session is still good.
enum _SessionConfirmation {
  /// The account still exists; the session is a live sign-in.
  confirmed,

  /// Supabase rejected the session: the account was deleted, or the token is
  /// no longer accepted. The local session must be cleared.
  rejected,

  /// Supabase could not be reached. Nothing is proven, so the local session
  /// is kept: a temporary network problem must never sign the user out.
  unconfirmed,
}

/// A marker emitted by [watchAuthState] when a password-recovery session is
/// active. The presentation layer uses this to route to the Reset Password
/// screen without requiring a manual OTP.
class PasswordRecoverySession {
  const PasswordRecoverySession(this.user);

  final AuthUser user;
}

/// [AuthRepository] backed by Supabase Auth.
///
/// Also owns the signup-confirmation guard. Opening
/// `kAuthEmailRedirectTo` makes Supabase exchange the emailed confirmation
/// link for a real session, which would drop the user straight into the
/// authenticated home screen. The required flow instead ends at Sign In, so
/// this repository closes that session again. See [watchAuthState].
///
/// Password recovery is handled separately: the recovery link opens the app
/// with a `passwordRecovery` auth event. The stream emits a special
/// [PasswordRecoverySession] wrapper so the presentation layer can route to
/// the Reset Password screen without requiring a manual OTP.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource) {
    ready = _restorePendingEmail();
  }

  /// Local key holding the address that is still awaiting its confirmation
  /// link. Deliberately local: never mirrored to Supabase.
  static const String pendingEmailKey = 'auth.pending_email_confirmation';

  final AuthDataSource _dataSource;

  /// Completes once the pending-confirmation marker has been read from
  /// storage. [main] awaits this before the first frame so that [currentUser]
  /// is already guarded when `AuthBloc` performs its startup check.
  late final Future<void> ready;

  /// Mirror of the stored marker, kept in memory so the synchronous
  /// [currentUser] getter can apply the same rule as [watchAuthState].
  String? _pendingEmail;

  /// Reads the marker eagerly so [currentUser] never reports a
  /// just-confirmed account before the guard can act on it.
  Future<void> _restorePendingEmail() async {
    _pendingEmail = await _readPendingEmail();
  }

  Future<String?> _readPendingEmail() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getString(pendingEmailKey);
    } on Exception catch (error) {
      // A storage failure must not break sign-in; treat the account as if it
      // were not awaiting confirmation rather than trapping the user.
      debugPrint('Failed to read pending confirmation email: $error');
      return null;
    }
  }

  /// Records that [email] must confirm its link before signing in.
  Future<void> _rememberPendingEmail(String email) async {
    _pendingEmail = email;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(pendingEmailKey, email);
    } on Exception catch (error) {
      debugPrint('Failed to persist pending confirmation email: $error');
    }
  }

  /// Forgets the marker. Always called *before* any sign-out so a misfire can
  /// never lock the user out of signing in.
  Future<void> _forgetPendingEmail() async {
    _pendingEmail = null;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(pendingEmailKey);
    } on Exception catch (error) {
      debugPrint('Failed to clear pending confirmation email: $error');
    }
  }

  bool _sameEmail(String? a, String? b) =>
      a != null &&
      b != null &&
      a.trim().toLowerCase() == b.trim().toLowerCase();

  /// Whether [state] is the session Supabase opened from the emailed
  /// signup-confirmation link for the account awaiting confirmation.
  ///
  /// Password recovery is explicitly excluded: `resetPasswordForEmail` stores
  /// its PKCE verifier under the `passwordRecovery` event name, so
  /// `exchangeCodeForSession` reports [AuthChangeEvent.passwordRecovery] for a
  /// recovery link and [AuthChangeEvent.signedIn] for a signup confirmation.
  /// Only the latter is dropped, so password recovery keeps working unchanged.
  ///
  /// Restoration is excluded too: a restored session arrives as an initial
  /// event, never as [AuthChangeEvent.signedIn].
  bool _isSignupConfirmationSession(AuthState state) {
    if (state.event != AuthChangeEvent.signedIn) return false;
    final user = state.session?.user;
    if (user == null || user.email == null) return false;
    return _sameEmail(_pendingEmail, user.email);
  }

  @override
  Stream<Object?> watchAuthState() {
    // asyncMap keeps events ordered, so a guard-triggered sign-out cannot
    // overtake a later real sign-in.
    //
    // The session restored at startup is confirmed with Supabase before the
    // app is told about it: a session cached on the device can outlive the
    // account it belongs to, and Supabase does not clear the device's copy
    // when an account is deleted from the dashboard.
    //
    // Password recovery sessions arrive as [AuthChangeEvent.passwordRecovery]
    // and are wrapped in [PasswordRecoverySession] so the presentation layer
    // can route to the Reset Password screen.
    var startupHandled = false;
    return _dataSource.onAuthStateChanged.asyncMap((state) async {
      if (_isSignupConfirmationSession(state)) {
        // Forget first, sign out second: even if this ever misfires, the next
        // manual sign-in is untouched, so the user cannot get stuck in a loop.
        await _forgetPendingEmail();
        await _dataSource.signOut();
        return null;
      }
      // Password recovery: the user clicked the recovery link. Wrap the user
      // so the presentation layer knows to show the Reset Password screen.
      if (state.event == AuthChangeEvent.passwordRecovery) {
        final user = _toUser(state.session?.user);
        if (user != null) return PasswordRecoverySession(user);
      }
      final user = _toUser(state.session?.user);
      // A restored session arrives as an initial event; the first event seen
      // is confirmed as well, so a session that was already in place when the
      // app started is never trusted blindly.
      final isRestoredSession =
          !startupHandled || state.event == AuthChangeEvent.initialSession;
      startupHandled = true;
      if (!isRestoredSession) return user;
      return _confirmRestoredSession(user);
    });
  }

  /// Checks the session restored at startup with Supabase.
  ///
  /// Returns the user when the account still exists, `null` when the session
  /// is definitively invalid (the account was deleted or the token was
  /// rejected) and the cached user when Supabase could not be reached, so a
  /// temporary network problem never signs the user out.
  Future<AuthUser?> _confirmRestoredSession(AuthUser? cached) async {
    if (cached == null) return null;

    final confirmation = await _confirmWithSupabase();
    switch (confirmation) {
      case _SessionConfirmation.confirmed:
        return cached;
      case _SessionConfirmation.unconfirmed:
        // Nothing was proven: keep the local session rather than throwing the
        // user out because the network happened to be down.
        debugPrint(
          'Could not confirm the restored session with Supabase; '
          'keeping the local session.',
        );
        return cached;
      case _SessionConfirmation.rejected:
        await _clearRejectedSession();
        return null;
    }
  }

  /// Asks Supabase whether the stored session still belongs to an account.
  Future<_SessionConfirmation> _confirmWithSupabase() async {
    try {
      // The data source throws when the session belongs to no account, so a
      // returned user is proof that the account still exists.
      await _withTimeout(
        _dataSource.getCurrentUser(),
        kSessionConfirmationTimeout,
      );
      return _SessionConfirmation.confirmed;
    } on AuthException catch (error) {
      if (_isDefinitiveRejection(error)) {
        debugPrint('Supabase rejected the restored session: $error');
        return _SessionConfirmation.rejected;
      }
      // A network error, a timeout or a server-side failure says nothing
      // about the account itself.
      debugPrint('Could not confirm the restored session: $error');
      return _SessionConfirmation.unconfirmed;
    } catch (error) {
      debugPrint('Could not confirm the restored session: $error');
      return _SessionConfirmation.unconfirmed;
    }
  }

  /// Whether [error] proves the session is no longer usable.
  ///
  /// Only a definitive answer from the Auth server counts. Everything else
  /// (offline, timeout, rate limit, server error) leaves the session alone.
  bool _isDefinitiveRejection(AuthException error) {
    final status = int.tryParse(error.statusCode ?? '');
    if (status == null) return false;
    return status == 400 || status == 401 || status == 403 || status == 404;
  }

  /// Removes a session Supabase no longer accepts from the device.
  ///
  /// Uses the supported sign-out, which clears the locally stored session
  /// and notifies the auth stream, so the app stops treating the account as
  /// signed in.
  Future<void> _clearRejectedSession() async {
    try {
      await _dataSource.signOut();
    } on Exception catch (error) {
      debugPrint('Failed to clear the rejected session: $error');
    }
  }

  /// Runs [future], giving up after [timeout].
  ///
  /// The timer is cancelled as soon as [future] settles, so a pending timer
  /// is never left behind.
  Future<T> _withTimeout<T>(Future<T> future, Duration timeout) {
    final completer = Completer<T>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('The session check timed out.', timeout),
        );
      }
    });
    future.then(
      (value) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(value);
      },
      onError: (Object error, StackTrace stackTrace) {
        timer.cancel();
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      },
    );
    return completer.future;
  }

  @override
  AuthUser? get currentUser {
    final user = _toUser(_dataSource.currentUser);
    // Mirrors [watchAuthState] for the narrow window where a confirmation
    // session exists before its sign-out has been processed.
    if (user == null || !_sameEmail(_pendingEmail, user.email)) return user;
    return null;
  }

  AuthUser? _toUser(User? user) =>
      user == null ? null : AuthUserModel.fromUser(user);

  @override
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // A deliberate, typed sign-in is never the confirmation callback, so the
      // guard in [watchAuthState] must not touch it. Clearing the marker first
      // — before the credential round trip — guarantees that, and it also
      // discards a stale marker left by a signup whose link was never opened.
      if (_sameEmail(_pendingEmail, email)) {
        await _forgetPendingEmail();
      }
      final response = await _dataSource.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user ?? response.session?.user;
      if (user == null) {
        throw const AuthFailure('Sign in failed. Please try again.');
      }
      return AuthUserModel.fromUser(user);
    } on AuthException catch (e) {
      throw AuthFailure(AuthErrorMapper.map(e));
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(AuthErrorMapper.mapUnknown(e));
    }
  }

  @override
  Future<AuthUser> signUpWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dataSource.signUp(
        email: email,
        password: password,
        data: {'first_name': firstName.trim(), 'last_name': lastName.trim()},
      );
      final user = response.user ?? response.session?.user;
      if (user == null) {
        throw const AuthFailure('Sign up failed. Please try again.');
      }
      // Sign-up must never leave the user authenticated: the required flow is
      // signup -> confirmation link -> manual password sign-in. Supabase
      // normally returns no session here (confirmation is required), but a
      // project with "Confirm email" disabled does return one. Dropping it
      // keeps the flow identical in both configurations and, because the drop
      // runs before the method returns, it cannot race the confirmation
      // callback into the authenticated home screen.
      if (response.session != null) {
        await _dataSource.signOut();
      }
      // Record the address only after the signup has definitely succeeded, so
      // the confirmation-pending screen is never shown for a failed attempt.
      // The link cannot be opened before this point, so there is no window in
      // which the callback arrives with no marker recorded.
      await _rememberPendingEmail(user.email ?? email);
      return AuthUserModel.fromUser(user);
    } on AuthException catch (e) {
      throw AuthFailure(AuthErrorMapper.map(e));
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(AuthErrorMapper.mapUnknown(e));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
    } on AuthException catch (e) {
      throw AuthFailure(AuthErrorMapper.map(e));
    } catch (e) {
      throw AuthFailure(AuthErrorMapper.mapUnknown(e));
    }
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {
    try {
      // The password-recovery session is already active; just update the
      // password. No OTP verification needed.
      await _dataSource.updatePassword(newPassword);
    } on AuthException catch (e) {
      throw AuthFailure(AuthErrorMapper.map(e));
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(AuthErrorMapper.mapUnknown(e));
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Supabase re-authenticates the session with the current password before
      // accepting a new one. Passing the real current password is what makes
      // this a genuine security check rather than a silent overwrite.
      await _dataSource.updatePassword(
        newPassword,
        currentPassword: currentPassword,
      );
    } on AuthException catch (e) {
      throw AuthFailure(AuthErrorMapper.map(e));
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(AuthErrorMapper.mapUnknown(e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(AuthErrorMapper.map(e));
    } catch (e) {
      throw AuthFailure(AuthErrorMapper.mapUnknown(e));
    }
  }
}
