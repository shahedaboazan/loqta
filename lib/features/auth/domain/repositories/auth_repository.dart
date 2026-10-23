import 'package:loqta/features/auth/domain/entities/auth_entities.dart';
import 'package:loqta/features/auth/domain/errors/auth_failure.dart';

/// Contract for the authentication repository.
///
/// Implementations live in the data layer. Methods throw [AuthFailure]
/// with a user-facing message on error.
abstract class AuthRepository {
  /// Stream of authentication state changes.
  ///
  /// Emits one of:
  /// - `AuthUser` — a confirmed, authenticated session.
  /// - `PasswordRecoverySession` — a password-recovery session (user clicked
  ///   the recovery link). The presentation layer should route to the Reset
  ///   Password screen.
  /// - `null` — no session (signed out).
  ///
  /// Emits the persisted session state immediately on subscription so the
  /// app can restore the session on startup.
  ///
  /// The session restored at startup is confirmed with the backend before it
  /// is reported as a sign-in, so a session cached on the device whose
  /// account no longer exists is never treated as a live sign-in. When the
  /// backend cannot be reached the local session is kept, because a
  /// temporary network problem is not proof of a deleted account.
  ///
  /// Implementations must not emit a user for the session Supabase opens when
  /// the signup-confirmation link is opened: that flow ends at Sign In, not at
  /// the authenticated home screen. Restored sessions and sessions from the
  /// password-recovery link must be emitted unchanged.
  Stream<Object?> watchAuthState();

  /// The currently signed-in user, or `null` when there is no session.
  ///
  /// This is the locally stored session. It is only a hint: the authoritative
  /// answer about the session comes from [watchAuthState], which confirms the
  /// restored session with the backend.
  AuthUser? get currentUser;

  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Registers a new account with an email and a password.
  ///
  /// Supabase emails a confirmation link and returns no session, so the
  /// returned [AuthUser] describes the new account and is *not* signed in.
  /// The user must confirm the link and then sign in manually.
  Future<AuthUser> signUpWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  /// Sends a password reset email to [email].
  Future<void> sendPasswordResetEmail(String email);

  /// Updates the password using the active password-recovery session.
  ///
  /// The session is established when the user opens the recovery link from the
  /// email. No separate recovery code is required.
  Future<void> resetPassword({required String newPassword});

  Future<void> signOut();

  /// Changes the password of the currently signed-in user.
  ///
  /// [currentPassword] is required and verified by Supabase, so this is an
  /// authenticated change rather than an unauthenticated overwrite. Throws
  /// [AuthFailure] with a user-facing message when the current password is
  /// wrong or the update is rejected.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
