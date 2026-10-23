import 'package:flutter/material.dart';

/// Loqta brand tokens for the light theme.
///
/// Values come from `design_drafts/design_spec.md` and were cross-checked
/// against the approved screenshots in `design_drafts/screens/`.
class LoqtaColors {
  LoqtaColors._();

  /// Primary brand green, used for every primary action.
  static const primary = Color(0xFF048444);

  /// Darker green used for pressed/hover states and the primary button fill.
  static const primaryDark = Color(0xFF00693A);

  /// Secondary brand green (promo pills, donation accents).
  static const secondaryGreen = Color(0xFF3A9F48);

  /// Cyan brand accent.
  static const accentCyan = Color(0xFF00BBD7);

  /// Primary heading/text colour mandated by the design specification.
  static const headingPrimary = Color(0xFF1E293B);

  /// Body text colour on light surfaces.
  static const textPrimary = Color(0xFF334155);

  /// Muted/supporting text (subtitles, hints, captions).
  static const textSecondary = Color(0xFF64748B);

  /// Faintest text (placeholders inside fields).
  static const textTertiary = Color(0xFF94A3B8);

  /// App background behind the auth and onboarding screens.
  static const background = Color(0xFFFFFFFF);

  /// Card / sheet surface.
  static const surface = Color(0xFFFFFFFF);

  /// Neutral fill used by every text field in the new design.
  static const fieldFill = Color(0xFFF2F4F7);

  /// Very light mint used behind the onboarding illustration panels.
  static const surfaceMint = Color(0xFFEFF9F3);

  /// Light cyan used behind the "sell / give" illustration panel.
  static const surfaceCyan = Color(0xFFEFF7FA);

  /// Tint behind informational banners and the verification helper text.
  static const infoSurface = Color(0xFFF0F6FD);

  /// Border used by informational banners.
  static const infoBorder = Color(0xFFD9E7F8);

  /// Tint behind the small green pill badges ("Almost ready to explore",
  /// "Loqta Secure Guard").
  static const pillSurface = Color(0xFFDDF5E6);

  /// Hairline dividers and field borders.
  static const border = Color(0xFFE5E7EB);

  /// Inactive page-indicator dots.
  static const progressInactive = Color(0xFFD8DEE4);

  /// Error / destructive colour.
  static const error = Color(0xFFD92D20);
}

/// Spacing and radius scale used by the new screens, kept in one place so the
/// rebuilt layouts stay consistent.
class LoqtaSpacing {
  LoqtaSpacing._();

  /// Standard horizontal screen gutter.
  static const double gutter = 20;

  /// Max content width so the layout does not stretch on tablets/foldables.
  static const double maxContentWidth = 440;

  static const double radiusCard = 20;
  static const double radiusField = 12;
  static const double radiusButton = 12;
}

/// Semantic Loqta colours, resolved from the ambient [ThemeData].
///
/// The brand values live in [LoqtaColors] as the light-mode source of truth.
/// This [ThemeExtension] is how dark mode works: [LoqtaTheme.dark] supplies a
/// second set of values for the *same* roles, and widgets read the role they
/// need through `context.loqtaColors`. That keeps a single theme definition
/// per mode and avoids scattering `isDark ? a : b` checks through the widget
/// tree.
@immutable
class LoqtaPalette extends ThemeExtension<LoqtaPalette> {
  const LoqtaPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.fieldFill,
    required this.onSurface,
    required this.heading,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.fieldBorder,
    required this.divider,
    required this.saleAccent,
    required this.saleSurface,
    required this.donationAccent,
    required this.donationSurface,
    required this.infoSurface,
    required this.infoBorder,
    required this.pillSurface,
    required this.pillOnSurface,
    required this.dangerSurface,
    required this.shadow,
  });

  /// The page background behind every screen.
  final Color background;

  /// Cards, sheets and panels.
  final Color surface;

  /// A surface resting above [surface], e.g. an elevated picker or a badge.
  final Color surfaceRaised;

  /// Neutral fill behind text fields.
  final Color fieldFill;

  /// Body text on [surface].
  final Color onSurface;

  /// Headings and screen titles.
  final Color heading;

  /// Muted supporting copy.
  final Color textSecondary;

  /// Placeholders and disabled text.
  final Color textTertiary;

  /// Outline on cards and inputs.
  final Color border;

  /// Outline on text fields specifically.
  final Color fieldBorder;

  /// Hairline dividers.
  final Color divider;

  /// Accent for "For Sale" listings (brand green in light mode).
  final Color saleAccent;

  /// Surface behind a "For Sale" badge.
  final Color saleSurface;

  /// Accent for "For Donation" listings (cyan in light mode).
  final Color donationAccent;

  /// Surface behind a "For Donation" badge.
  final Color donationSurface;

  /// Tint behind informational banners.
  final Color infoSurface;

  /// Border on informational banners.
  final Color infoBorder;

  /// Tint behind small status pills.
  final Color pillSurface;

  /// Text/icon colour on [pillSurface].
  final Color pillOnSurface;

  /// Tint behind destructive rows and buttons.
  final Color dangerSurface;

  /// Soft drop shadow for floating elements.
  final Color shadow;

  /// The light-mode palette. Mirrors the brand tokens above.
  static const LoqtaPalette lightPalette = LoqtaPalette(
    background: LoqtaColors.background,
    surface: LoqtaColors.surface,
    surfaceRaised: Color(0xFFF8FAFC),
    fieldFill: LoqtaColors.fieldFill,
    onSurface: LoqtaColors.textPrimary,
    heading: LoqtaColors.headingPrimary,
    textSecondary: LoqtaColors.textSecondary,
    textTertiary: LoqtaColors.textTertiary,
    border: LoqtaColors.border,
    fieldBorder: LoqtaColors.border,
    divider: LoqtaColors.border,
    saleAccent: LoqtaColors.primary,
    saleSurface: LoqtaColors.pillSurface,
    donationAccent: Color(0xFF007A8A),
    donationSurface: LoqtaColors.surfaceCyan,
    infoSurface: LoqtaColors.infoSurface,
    infoBorder: LoqtaColors.infoBorder,
    pillSurface: LoqtaColors.pillSurface,
    pillOnSurface: Color(0xFF0B6B3A),
    dangerSurface: Color(0xFFFDECEA),
    shadow: Color(0x140F172A),
  );

  /// The dark-mode palette.
  ///
  /// The brand green is lightened for legibility against dark surfaces; the
  /// Cyan accent is likewise raised so donation badges keep enough contrast.
  /// Values are hand-tuned rather than mechanically inverted, because a literal
  /// inversion produces muddy, low-contrast greens.
  static const LoqtaPalette darkPalette = LoqtaPalette(
    background: Color(0xFF0B1220),
    surface: Color(0xFF131C2E),
    surfaceRaised: Color(0xFF1B2639),
    fieldFill: Color(0xFF1B2639),
    onSurface: Color(0xFFE2E8F0),
    heading: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textTertiary: Color(0xFF64748B),
    border: Color(0xFF24314A),
    fieldBorder: Color(0xFF2C3A54),
    divider: Color(0xFF1F2B40),
    saleAccent: Color(0xFF34D399),
    saleSurface: Color(0xFF123527),
    donationAccent: Color(0xFF22D3EE),
    donationSurface: Color(0xFF0B3A44),
    infoSurface: Color(0xFF13283F),
    infoBorder: Color(0xFF1D3E5C),
    pillSurface: Color(0xFF123527),
    pillOnSurface: Color(0xFF6EE7B7),
    dangerSurface: Color(0xFF3B1D1D),
    shadow: Color(0x66000000),
  );

  @override
  LoqtaPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? fieldFill,
    Color? onSurface,
    Color? heading,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? fieldBorder,
    Color? divider,
    Color? saleAccent,
    Color? saleSurface,
    Color? donationAccent,
    Color? donationSurface,
    Color? infoSurface,
    Color? infoBorder,
    Color? pillSurface,
    Color? pillOnSurface,
    Color? dangerSurface,
    Color? shadow,
  }) {
    return LoqtaPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      fieldFill: fieldFill ?? this.fieldFill,
      onSurface: onSurface ?? this.onSurface,
      heading: heading ?? this.heading,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      fieldBorder: fieldBorder ?? this.fieldBorder,
      divider: divider ?? this.divider,
      saleAccent: saleAccent ?? this.saleAccent,
      saleSurface: saleSurface ?? this.saleSurface,
      donationAccent: donationAccent ?? this.donationAccent,
      donationSurface: donationSurface ?? this.donationSurface,
      infoSurface: infoSurface ?? this.infoSurface,
      infoBorder: infoBorder ?? this.infoBorder,
      pillSurface: pillSurface ?? this.pillSurface,
      pillOnSurface: pillOnSurface ?? this.pillOnSurface,
      dangerSurface: dangerSurface ?? this.dangerSurface,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  LoqtaPalette lerp(LoqtaPalette? other, double t) {
    if (other == null) return this;
    return LoqtaPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      heading: Color.lerp(heading, other.heading, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      saleAccent: Color.lerp(saleAccent, other.saleAccent, t)!,
      saleSurface: Color.lerp(saleSurface, other.saleSurface, t)!,
      donationAccent: Color.lerp(donationAccent, other.donationAccent, t)!,
      donationSurface: Color.lerp(donationSurface, other.donationSurface, t)!,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t)!,
      infoBorder: Color.lerp(infoBorder, other.infoBorder, t)!,
      pillSurface: Color.lerp(pillSurface, other.pillSurface, t)!,
      pillOnSurface: Color.lerp(pillOnSurface, other.pillOnSurface, t)!,
      dangerSurface: Color.lerp(dangerSurface, other.dangerSurface, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Resolves the [LoqtaPalette] for the ambient theme.
///
/// Falls back to the light palette when no theme is installed, so widgets used
/// in isolation (tests, tooling) still render with sensible colours.
extension LoqtaPaletteX on BuildContext {
  LoqtaPalette get loqtaColors =>
      Theme.of(this).extension<LoqtaPalette>() ?? LoqtaPalette.lightPalette;

  /// True when the ambient theme is dark.
  bool get isLoqtaDark => Theme.of(this).brightness == Brightness.dark;
}

/// Text styles used across the rebuilt screens.
///
/// The sizes mirror the approved screenshots: large bold headings, small
/// uppercase/medium labels, and muted supporting copy.
class LoqtaText {
  LoqtaText._();

  static const String family = 'Inter';

  static const TextStyle screenTitle = TextStyle(
    color: LoqtaColors.headingPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: family,
    height: 1.2,
  );

  /// Large centred heading, e.g. "Welcome Back", "Create Your Account".
  static const TextStyle heading = TextStyle(
    color: LoqtaColors.headingPrimary,
    fontSize: 25,
    fontWeight: FontWeight.w700,
    fontFamily: family,
    letterSpacing: -0.4,
    height: 1.2,
  );

  /// Muted supporting line under a heading.
  static const TextStyle subtitle = TextStyle(
    color: LoqtaColors.textSecondary,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    fontFamily: family,
    height: 1.45,
  );

  /// Field label sitting above the input.
  static const TextStyle fieldLabel = TextStyle(
    color: LoqtaColors.headingPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontFamily: family,
  );

  static const TextStyle fieldHint = TextStyle(
    color: LoqtaColors.textTertiary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: family,
  );

  static const TextStyle body = TextStyle(
    color: LoqtaColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: family,
    height: 1.4,
  );

  /// Small caption used for trust lines and helper text.
  static const TextStyle caption = TextStyle(
    color: LoqtaColors.textSecondary,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    fontFamily: family,
    height: 1.35,
  );

  static const TextStyle button = TextStyle(
    color: Colors.white,
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    fontFamily: family,
  );

  /// Green inline link, e.g. "Create Account", "Resend Code".
  static const TextStyle link = TextStyle(
    color: LoqtaColors.primary,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    fontFamily: family,
  );
}

class LoqtaTheme {
  LoqtaTheme._();

  static ThemeData get light => _build(LoqtaPalette.lightPalette);

  static ThemeData get dark => _build(LoqtaPalette.darkPalette);

  /// Builds a [ThemeData] for one [palette].
  ///
  /// Both modes come from this single builder so a change to, say, input
  /// decoration applies identically in light and dark — which is what keeps the
  /// two modes from drifting apart as the app grows.
  static ThemeData _build(LoqtaPalette palette) {
    final isDark = palette == LoqtaPalette.darkPalette;

    // The color scheme's brightness must match ThemeData.brightness. Using the
    // dark palette with ColorScheme.light would trip Flutter's assertion and,
    // even without it, leave Material components resolving light-mode colors.
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: const Color(0xFF34D399),
            onPrimary: const Color(0xFF04231A),
            secondary: const Color(0xFF22D3EE),
            onSecondary: const Color(0xFF04252B),
            surface: palette.surface,
            onSurface: palette.onSurface,
            outline: palette.border,
            error: const Color(0xFFF87171),
          )
        : ColorScheme.light(
            primary: LoqtaColors.primary,
            onPrimary: Colors.white,
            secondary: LoqtaColors.secondaryGreen,
            onSecondary: Colors.white,
            surface: palette.surface,
            onSurface: palette.onSurface,
            outline: palette.border,
            error: LoqtaColors.error,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      extensions: <ThemeExtension<dynamic>>[palette],
      fontFamily: LoqtaText.family,
      splashFactory: InkSparkle.splashFactory,

      // The rebuilt screens draw their own top bar (see LoqtaAppBar) so the
      // Material AppBar is kept minimal for any incidental use.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.heading,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),

      // Fields are flat, filled and borderless; validation is surfaced by the
      // helper line the screens render under each field.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.fieldFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        hintStyle: LoqtaText.fieldHint.copyWith(color: palette.textTertiary),
        border: _noBorder,
        enabledBorder: _noBorder,
        focusedBorder: _noBorder,
        errorBorder: _noBorder,
        focusedErrorBorder: _noBorder,
        disabledBorder: _noBorder,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: 0.2),
        selectionHandleColor: colorScheme.primary,
      ),

      textTheme: TextTheme(
        displaySmall: LoqtaText.heading.copyWith(color: palette.heading),
        headlineLarge: LoqtaText.heading.copyWith(color: palette.heading),
        headlineMedium: LoqtaText.heading.copyWith(color: palette.heading),
        headlineSmall: LoqtaText.screenTitle.copyWith(color: palette.heading),
        titleLarge: LoqtaText.screenTitle.copyWith(color: palette.heading),
        titleMedium: LoqtaText.fieldLabel.copyWith(color: palette.heading),
        titleSmall: LoqtaText.caption.copyWith(color: palette.textSecondary),
        bodyLarge: LoqtaText.body.copyWith(color: palette.onSurface),
        bodyMedium: LoqtaText.body.copyWith(color: palette.onSurface),
        bodySmall: LoqtaText.caption.copyWith(color: palette.textSecondary),
        labelLarge: LoqtaText.button,
        labelMedium: LoqtaText.caption.copyWith(color: palette.textSecondary),
        labelSmall: LoqtaText.caption.copyWith(color: palette.textSecondary),
      ),

      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.heading,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontFamily: LoqtaText.family,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LoqtaSpacing.radiusField),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LoqtaSpacing.radiusCard),
        ),
      ),
    );
  }

  static const _noBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(LoqtaSpacing.radiusField)),
    borderSide: BorderSide.none,
  );
}
