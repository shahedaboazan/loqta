import 'package:loqta/features/settings/domain/entities/app_preferences.dart';

/// Reads and writes the device-local display preferences.
///
/// Kept behind an interface so the Settings BLoC has no knowledge of
/// SharedPreferences, and so tests can substitute an in-memory implementation.
abstract interface class SettingsRepository {
  /// Loads the stored preferences.
  ///
  /// Must never throw: a storage failure should degrade to the defaults rather
  /// than block the app from starting.
  Future<AppPreferences> load();

  /// Persists the language code. Pass null to follow the device locale.
  Future<void> saveLocale(String? languageCode);

  /// Persists the brightness selection.
  Future<void> saveThemeMode(AppThemeMode mode);
}
