/// Local, on-device store for whether the user has finished onboarding.
///
/// This flag is deliberately local-only: it is never written to Supabase and
/// it must not be cleared when the user signs out, so that returning users are
/// not forced through onboarding again.
abstract class OnboardingRepository {
  /// Whether onboarding has been completed or skipped at least once.
  Future<bool> isOnboardingCompleted();

  /// Marks onboarding as completed or skipped and persists it locally.
  Future<void> completeOnboarding();
}
