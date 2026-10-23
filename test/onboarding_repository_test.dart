import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:loqta/features/onboarding/data/repositories/onboarding_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingRepositoryImpl', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to false when nothing has been stored', () async {
      final repository = OnboardingRepositoryImpl();

      expect(await repository.isOnboardingCompleted(), isFalse);
    });

    test('persists the completed flag across repository instances', () async {
      await OnboardingRepositoryImpl().completeOnboarding();

      // A new instance reads the same backing store, standing in for an app
      // restart.
      final afterRestart = OnboardingRepositoryImpl();
      expect(await afterRestart.isOnboardingCompleted(), isTrue);
    });

    test('the flag survives a simulated app restart', () async {
      SharedPreferences.setMockInitialValues({
        OnboardingRepositoryImpl.completedKey: true,
      });

      expect(await OnboardingRepositoryImpl().isOnboardingCompleted(), isTrue);
    });

    test('completing onboarding writes the documented key', () async {
      await OnboardingRepositoryImpl().completeOnboarding();

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getBool(OnboardingRepositoryImpl.completedKey),
        isTrue,
      );
    });

    test('an unrelated stored flag does not mark onboarding complete', () {
      SharedPreferences.setMockInitialValues({'some_other_key': true});

      return expect(
        OnboardingRepositoryImpl().isOnboardingCompleted(),
        completion(isFalse),
      );
    });

    test('the flag is stored locally, never alongside auth data', () async {
      await OnboardingRepositoryImpl().completeOnboarding();

      final preferences = await SharedPreferences.getInstance();
      final keys = preferences.getKeys();

      expect(keys, contains(OnboardingRepositoryImpl.completedKey));
      expect(keys.where((k) => k.toLowerCase().contains('supabase')), isEmpty);
      expect(keys.where((k) => k.toLowerCase().contains('token')), isEmpty);
      expect(keys.where((k) => k.toLowerCase().contains('session')), isEmpty);
    });

    test('completing twice is idempotent', () async {
      final repository = OnboardingRepositoryImpl();

      await repository.completeOnboarding();
      await repository.completeOnboarding();

      expect(await repository.isOnboardingCompleted(), isTrue);
    });
  });
}
