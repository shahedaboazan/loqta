import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:loqta/features/settings/domain/entities/app_preferences.dart';
import 'package:loqta/features/settings/domain/repositories/settings_repository.dart';

/// [SettingsRepository] backed by [SharedPreferences].
///
/// Every read is best-effort. A failed read falls back to the defaults
/// (system locale, light theme) and a failed write is logged but not surfaced as
/// a failure to the user: the in-memory selection still applies for this
/// session, which is far better than stranding them on an error.
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl();

  static const String localeKey = 'app_locale_code';
  static const String themeKey = 'app_theme_mode';

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  @override
  Future<AppPreferences> load() async {
    try {
      final preferences = await _preferences;
      return AppPreferences(
        localeCode: preferences.getString(localeKey),
        themeMode: appThemeModeFromStorage(preferences.getString(themeKey)),
      );
    } on Exception catch (error, stackTrace) {
      debugPrint('Failed to load app preferences: $error\n$stackTrace');
      return const AppPreferences(themeMode: AppThemeMode.light);
    }
  }

  @override
  Future<void> saveLocale(String? languageCode) async {
    try {
      final preferences = await _preferences;
      if (languageCode == null) {
        await preferences.remove(localeKey);
      } else {
        await preferences.setString(localeKey, languageCode);
      }
    } on Exception catch (error, stackTrace) {
      debugPrint('Failed to persist locale: $error\n$stackTrace');
    }
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    try {
      final preferences = await _preferences;
      await preferences.setString(themeKey, mode.storageValue);
    } on Exception catch (error, stackTrace) {
      debugPrint('Failed to persist theme mode: $error\n$stackTrace');
    }
  }
}
