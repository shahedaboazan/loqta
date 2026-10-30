/// The shared Syrian governorate → area hierarchy.
///
/// Location in Loqta is **always** selected manually as Governorate → Area.
/// There is no GPS, no map picker and no current-location detection anywhere in
/// the app, so this file is the single source of truth for the supported
/// governorates.
///
/// It lives in `core` rather than in a feature because both listing creation and
/// profile editing need it; keeping one copy stops the two pickers from
/// drifting apart or offering different areas.
class SyriaLocations {
  SyriaLocations._();

  /// Canonical English keys, ordered as in the product specification.
  ///
  /// The *stored* value is the English key, never the translated label, so a
  /// listing published in Arabic still sorts and matches alongside one published
  /// in English. Translation happens only at render time.
  static const List<String> governorateKeys = <String>[
    'Damascus',
    'Rural Damascus',
    'Aleppo',
    'Homs',
    'Hama',
    'Latakia',
    'Tartus',
    'Idlib',
    'Daraa',
    'As-Suwayda',
    'Quneitra',
    'Deir ez-Zor',
    'Raqqa',
    'Al-Hasakah',
  ];
}
