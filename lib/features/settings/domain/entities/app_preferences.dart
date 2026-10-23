import 'dart:ui' show Locale;

import 'package:equatable/equatable.dart';

/// Which brightness Loqta renders with.
///
/// A closed set rather than `ThemeMode` so the domain layer does not depend on
/// Flutter's widget layer.
enum AppThemeMode {
  light,
  dark;

  /// The name persisted in storage. Using a stable string rather than the enum
  /// index means reordering the enum can never silently reinterpret every
  /// user's saved preference.
  String get storageValue => name;
}

/// Parses a persisted [storageValue], falling back to [AppThemeMode.light] for
/// anything unrecognised (including values written by an older build).
AppThemeMode appThemeModeFromStorage(String? value) {
  return AppThemeMode.values.firstWhere(
    (mode) => mode.storageValue == value,
    orElse: () => AppThemeMode.light,
  );
}

/// The user's device-local display preferences.
///
/// Intentionally *not* synced to Supabase: language and brightness are
/// per-device settings, and persisting them locally means the choice survives
/// sign-out and reinstall-free restarts without touching the auth account.
class AppPreferences extends Equatable {
  const AppPreferences({this.localeCode, this.themeMode = AppThemeMode.light});

  /// BCP-47-ish language code (`en` / `ar`), or null to follow the system.
  final String? localeCode;

  final AppThemeMode themeMode;

  /// The [Locale] these preferences select, or null to follow the device
  /// locale via `MaterialApp.localeListResolutionCallback`.
  Locale? get resolvedLocale {
    final code = localeCode;
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  @override
  List<Object?> get props => [localeCode, themeMode];
}
