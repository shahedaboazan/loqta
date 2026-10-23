import 'package:supabase_flutter/supabase_flutter.dart';

/// Where Supabase should send the user after they click the email
/// confirmation link, passed as `emailRedirectTo` on sign-up.
///
/// The `loqta` scheme is registered on both platforms:
///  * Android: an `android.intent.action.VIEW` intent filter in
///    `android/app/src/main/AndroidManifest.xml`.
///  * iOS: a `CFBundleURLTypes` entry in `ios/Runner/Info.plist`.
///
/// The same URL must also appear in Supabase's allow-list under
/// Authentication -> URL Configuration -> Redirect URLs, otherwise Supabase
/// refuses to redirect to it.
///
/// `supabase_flutter` needs no extra setup for this: it already ships a
/// deep-link observer built on `app_links`, enabled by default
/// (`detectSessionInUri`), and the app runs the PKCE flow, so the link arrives
/// as `loqta://auth/confirm?code=...` and is exchanged for a session
/// automatically.
const String kAuthEmailRedirectTo = 'loqta://auth/confirm';

/// Where Supabase should send the user after they click the password
/// recovery link. This uses the same `loqta` scheme with a distinct path so
/// the app can distinguish recovery from email confirmation.
///
/// Must be added to Supabase's allowed redirect URLs alongside
/// `kAuthEmailRedirectTo`.
const String kAuthPasswordRecoveryRedirectTo = 'loqta://auth/reset';

/// Supabase authentication data source.
///
/// Thin wrapper around `Supabase.instance.client.auth` so the rest
/// of the app never touches the Supabase SDK directly.
class AuthDataSource {
  GoTrueClient get _auth => Supabase.instance.client.auth;

  /// Registers a new account with an email and a password.
  ///
  /// Supabase sends its standard confirmation email containing a link; it
  /// returns no session until that link is followed, so the caller must not
  /// treat the missing session as a failure.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
    String? emailRedirectTo = kAuthEmailRedirectTo,
  }) => _auth.signUp(
    email: email,
    password: password,
    emailRedirectTo: emailRedirectTo,
    data: data,
  );

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) => _auth.signInWithPassword(email: email, password: password);

  /// Sends a password recovery email with a link that opens the app.
  ///
  /// The `redirectTo` parameter tells Supabase to include a deep link in the
  /// email. When the user taps it, the app receives a `passwordRecovery` auth
  /// event with a valid session, and the Reset Password screen can update the
  /// password without requiring a manually entered OTP.
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.resetPasswordForEmail(
        email,
        redirectTo: kAuthPasswordRecoveryRedirectTo,
      );

  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  }) => _auth.verifyOTP(email: email, token: token, type: OtpType.recovery);

  Future<User> updatePassword(
    String newPassword, {
    String? currentPassword,
  }) async {
    final response = await _auth.updateUser(
      UserAttributes(
        password: newPassword,
        // Supplying the current password makes Supabase re-authenticate the
        // session before applying the change. Omitted by the password-recovery
        // flow, which is already authorised by the recovery link.
        nonce: currentPassword,
      ),
    );
    final user = response.user;
    if (user == null) {
      throw AuthException('Failed to update password.');
    }
    return user;
  }

  /// Confirms the current session with the Supabase Auth server.
  ///
  /// The session is refreshed first when its access token has expired, so a
  /// merely expired token is never mistaken for a deleted account. The Auth
  /// server is then asked for the user the session belongs to, which is the
  /// only reliable way to find out whether the account still exists.
  ///
  /// Throws [AuthException] when Supabase rejects the session (the account
  /// was deleted, the token is no longer accepted) and
  /// [AuthRetryableFetchException] when the request could not be completed at
  /// all (offline, server error). The two must not be confused: only the
  /// first proves the session is invalid.
  Future<User> getCurrentUser() async {
    // `getSession` refreshes an expired session on demand and returns `null`
    // when there is no session at all.
    final session = await _auth.getSession();
    if (session == null) {
      throw AuthSessionMissingException('There is no session to confirm.');
    }
    final response = await _auth.getUser();
    final user = response.user;
    if (user == null) {
      throw AuthException(
        'The session no longer belongs to a user.',
        statusCode: '404',
      );
    }
    return user;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<AuthState> get onAuthStateChanged => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;
}
