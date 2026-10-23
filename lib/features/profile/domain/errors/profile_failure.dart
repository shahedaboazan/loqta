/// Failures raised by the profile feature.
sealed class ProfileFailure implements Exception {
  const ProfileFailure(this.message);

  /// A message safe to show the user.
  final String message;

  @override
  String toString() => message;
}

/// The profile row could not be read or written.
class ProfileUnavailableFailure extends ProfileFailure {
  const ProfileUnavailableFailure([
    super.message = 'Could not load your profile. Please try again.',
  ]);
}

/// The profile update was rejected or failed to persist.
class ProfileUpdateFailure extends ProfileFailure {
  const ProfileUpdateFailure([
    super.message = 'Could not save your profile. Please try again.',
  ]);
}
