import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:loqta/core/localization/app_strings.dart';
import 'package:loqta/core/localization/app_strings_ar.dart';

/// Centralized localization for Loqta.
///
/// All user-facing copy lives in [AppStrings]; this class only resolves which
/// implementation to hand out for the active [Locale] and exposes it through
/// `Localizations`. Screens never construct a strings object themselves, so
/// switching language in Settings updates the whole app from one place, and
/// `MaterialApp` handles the LTR/RTL flip via [supportedLocales].
///
/// Usage:
/// ```dart
/// final s = context.l10t;
/// Text(s.signIn);
/// ```
class AppLocalizations {
  const AppLocalizations(this.locale, this.strings);

  /// The locale these strings were resolved for.
  final Locale locale;

  /// The resolved copy.
  final AppStrings strings;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// The locales the app ships translations for.
  ///
  /// The order matters: it is the fallback order used by
  /// `localeListResolutionCallback`, so English still resolves for any device
  /// locale Loqta has no translation for.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  /// The default locale, used before anything is persisted and as the final
  /// fallback.
  static const Locale fallbackLocale = Locale('en');

  /// The Arabic code, used by the Settings toggle.
  static const Locale arabic = Locale('ar');

  /// The English code, used by the Settings toggle.
  static const Locale english = Locale('en');

  /// Resolves the copy for [locale].
  static AppLocalizations of(BuildContext context) {
    final result = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    // A null result means the delegate was not installed. Returning English
    // keeps widgets usable in isolated tests and tooling rather than throwing.
    return result ?? const AppLocalizations(fallbackLocale, AppStringsEn());
  }

  /// True when the active locale reads right-to-left.
  bool get isRtl => locale.languageCode == 'ar';
}

extension AppLocalizationsX on BuildContext {
  /// Shorthand for `AppLocalizations.of(this).strings`.
  AppStrings get l10n => AppLocalizations.of(this).strings;

  /// Shorthand for the active [Locale].
  Locale get appLocale => AppLocalizations.of(this).locale;
}

/// Resolves a category `labelKey` to display text.
///
/// Data-driven components (the category strip, filters, pickers) store a key
/// rather than a label so they can be rendered from a plain list; this helper
/// is what turns that key into the active language's text, falling back to
/// [fallback] for a key this build has no translation for.
extension AppStringsX on AppStrings {
  String resolveCategory(String labelKey, String fallback) =>
      switch (labelKey) {
        'categoryAll' => categoryAll,
        'categoryFurniture' => categoryFurniture,
        'categoryElectronics' => categoryElectronics,
        'categoryAppliances' => categoryAppliances,
        'categoryClothes' => categoryClothes,
        'categoryShoes' => categoryShoes,
        'categoryKids' => categoryKids,
        'categoryBooks' => categoryBooks,
        'categoryHomeGarden' => categoryHomeGarden,
        'categorySports' => categorySports,
        'categoryVehicles' => categoryVehicles,
        'categoryPhones' => categoryPhones,
        'categoryComputers' => categoryComputers,
        'categoryJewelry' => categoryJewelry,
        'categoryToys' => categoryToys,
        'categoryOther' => categoryOther,
        _ => fallback,
      };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) {
    final languageCode = locale.languageCode.toLowerCase();
    // Arabic is the only right-to-left locale Loqta ships. Anything else falls
    // back to English so an unsupported device locale never shows a blank
    // screen.
    final strings = languageCode == 'ar'
        ? const AppStringsAr()
        : const AppStringsEn();
    return SynchronousFuture<AppLocalizations>(
      AppLocalizations(Locale(languageCode), strings),
    );
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
