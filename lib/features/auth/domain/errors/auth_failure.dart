/// Domain-level authentication failure.
///
/// The data layer maps SDK-specific errors (e.g. Supabase `AuthException`)
/// into this type so the presentation layer never depends on external SDKs.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}
