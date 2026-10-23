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

  /// Areas per governorate.
  ///
  /// Only the Damascus and Rural Damascus neighbourhoods are spelled out
  /// because the approved designs name them directly (Project Dummar, Al-Mazzeh,
  /// Al-Jadidah, Kafr Souqa, Al-Afid). For the remaining governorates this
  /// offers their principal districts and cities rather than inventing an
  /// exhaustive street-level database.
  static const Map<String, List<String>> areasByGovernorate =
      <String, List<String>>{
        'Damascus': <String>[
          'Al-Mazzeh',
          'Al-Jadidah',
          'Project Dummar',
          'Kafr Souqa',
          'Al-Afid',
          'Al-Yamarmouna',
          'Baramkeh',
          'Bab Tuma',
          'Bab Sharqi',
          'Wadi al-Mashari',
          'Al-Salihiyah',
          'Al-Midan',
          'Al-Qadam',
          'Al-Zabaltani',
          'Al-Arbash',
          'Kafr al-Sulwa',
          'Al-Jaish',
        ],
        'Rural Damascus': <String>[
          'Douma',
          'Jaramkeh',
          'Sabaa',
          'Haramkeh',
          'Qasyun',
          'Zabadani',
          'Yabroud',
          'Al-Tall',
          'Al-Nasr',
          'Rankous',
          'Rihab al-Sham',
          'Al-Mukharram',
          'Bebla',
          'Madaya',
          'Al-Harah',
        ],
        'Aleppo': <String>[
          'Al-Jamiliyah',
          'Al-Mansur',
          'Al-Sabil',
          'Al-Furqan',
          'Al-Shaar',
          'Al-Muhafaza',
          'Al-Kindi',
          'Sabil al-Kubra',
          'Al-Istikhlar',
          'Hanano',
          'Al-Suleimaniyah',
          'Khan al-Asil',
        ],
        'Homs': <String>[
          'Al-Wahda',
          'Al-Saa',
          'Al-Kindy',
          'Al-Nabulsiyah',
          'Furn',
          'Al-Jamiliyah',
          'Al-Qussary',
          'Al-Wadi',
          'Sit al-Watar',
          'Kafr Buhum',
        ],
        'Hama': <String>[
          'Al-Nour',
          'Al-Assad',
          'Al-Mudarres',
          'Al-Qaisar',
          'Sabil al-Dawr',
          'Al-Kahil',
          'Kafr Buhum',
        ],
        'Latakia': <String>[
          'Al-Sharawiyah',
          'Al-Sabil',
          'Az-Zahra',
          'Al-Andalus',
          'Qardaha',
          'Huwwash',
          'Al-Manshiyah',
        ],
        'Tartus': <String>[
          'Al-Manshiyah',
          'Qadmus',
          'Dhuhayr al-Wara',
          'Al-Buth',
          'Al-Hamra',
        ],
        'Idlib': <String>[
          'Al-Shaar',
          'Al-Mutanabbi',
          'Al-Furqan',
          'Al-Kawarna',
          'Sarqab',
          'Kafr al-Laha',
        ],
        'Daraa': <String>[
          'Al-Ashrafiyah',
          'Al-Qaytunah',
          'As-Salihiyah',
          'Al-Muhafaza',
          'Jazmah',
          'Sabaa',
        ],
        'As-Suwayda': <String>[
          'Al-Qurbaniyah',
          'As-Suwayda',
          'Al-Ghara',
          'Al-Druzeh',
        ],
        'Quneitra': <String>[
          'Quneitra',
          'Khan al-Arnabah',
          'Al-Ahsa',
          'Masaadeh',
        ],
        'Deir ez-Zor': <String>[
          'Al-Hasakah Al-Filistiniyah',
          'Al-Asad',
          'Al-Muallaqah',
          'Al-Jaafari',
          'Al-Buhasanah',
        ],
        'Raqqa': <String>[
          'Al-Rasheed',
          'Al-Sabil',
          'Al-Mukhtar',
          'Al-Julan',
          'Al-Ghashlaniyah',
        ],
        'Al-Hasakah': <String>[
          'Al-Nasr',
          'Al-Muhafaza',
          'Al-Rummani',
          'Al-Ghariyah',
          'Al-Hasakah',
        ],
      };

  /// The areas available for [governorate], or an empty list if the key is not
  /// one of the supported governorates.
  static List<String> areasFor(String governorate) {
    return areasByGovernorate[governorate] ?? const <String>[];
  }

  /// True when [area] genuinely belongs to [governorate].
  ///
  /// Used to validate the two-step picker: choosing an area before a
  /// governorate is selected, or an area that no longer matches the chosen
  /// governorate, must be rejected rather than silently kept.
  static bool areaBelongsTo(String governorate, String area) {
    return areasFor(governorate).contains(area);
  }
}
