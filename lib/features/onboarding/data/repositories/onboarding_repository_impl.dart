import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:loqta/features/onboarding/domain/repositories/onboarding_repository.dart';

/// [OnboardingRepository] backed by [SharedPreferences].
///
/// The flag lives under a single boolean key so it survives app restarts.
/// Sign-out never touches this key, so returning users are not forced
/// through onboarding again.
class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl();

  /// Key holding the local "onboarding completed" flag. Deliberately local:
  /// never mirrored to Supabase and never cleared on sign-out.
  static const String completedKey = 'onboarding_completed';

  // Resolved on each access rather than cached, so the repository always
  // reads the live backing store.
  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  @override
  Future<bool> isOnboardingCompleted() async {
    try {
      final preferences = await _preferences;
      return preferences.getBool(completedKey) ?? false;
    } on Exception catch (error, stackTrace) {
      // A storage failure must not block the app from starting; treat the
      // user as if they had not seen onboarding yet rather than stranding
      // them on the splash screen.
      debugPrint('Failed to read onboarding flag: $error\n$stackTrace');
      return false;
    }
  }

  @override
  Future<void> completeOnboarding() async {
    try {
      final preferences = await _preferences;
      await preferences.setBool(completedKey, true);
    } on Exception catch (error, stackTrace) {
      // Persistence is best-effort: navigating to sign-in matters more than
      // the write succeeding, otherwise the user would be trapped.
      debugPrint('Failed to persist onboarding flag: $error\n$stackTrace');
    }
  }
}
