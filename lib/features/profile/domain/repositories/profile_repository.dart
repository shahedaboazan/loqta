import 'package:loqta/features/profile/domain/entities/user_profile.dart';

/// Reads and writes the signed-in user's own profile row.
///
/// Writes are always scoped to the authenticated user by the `profiles_update_
/// self` RLS policy, so a caller cannot edit another account's profile even if
/// it passes a different id.
abstract interface class ProfileRepository {
  /// Loads the signed-in user's profile.
  ///
  /// Returns null when no row exists yet. Throws [ProfileFailure] on a transport
  /// or permission error, which the BLoC maps to a user-visible message.
  Future<UserProfile?> fetchCurrentProfile();

  /// Persists the editable profile fields.
  ///
  /// [email] is deliberately absent: the account email is owned by Supabase
  /// auth and must be changed through the auth flow, not the profile form.
  Future<UserProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? governorate,
    String? area,
    String? phoneNumber,
  });
}
