import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';

/// The shared user-avatar component.
///
/// One implementation is used everywhere a person is shown — the Profile header,
/// Edit Profile, conversation rows, listing seller summaries and the Home app
/// bar — so the fallback rule cannot differ from one screen to the next.
///
/// The rule is:
///  * when [imageUrl] is non-empty and loads, show the photo;
///  * otherwise show a circle with the first letter of [name];
///  * when [name] is blank too, fall back to a neutral person glyph rather than
///    an empty circle, which would look like a rendering bug.
///
/// [name] and [imageUrl] are language-neutral inputs; the caller supplies the
/// already-resolved display name.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// The person's display name, used only for the initial fallback.
  final String name;

  /// Absolute or public URL of the profile photo, if one exists.
  final String? imageUrl;

  /// Diameter of the circle.
  final double size;

  /// Overrides the fallback circle fill. Defaults to the brand green.
  final Color? backgroundColor;

  /// Overrides the initial/glyph colour. Defaults to white.
  final Color? foregroundColor;

  /// The first letter of [name], or null when the name has no letters.
  ///
  /// Exposed as a static so the same rule can be applied to any widget that
  /// needs the initial without instantiating an avatar.
  static String? initialOf(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    // Iterating runes rather than taking name[0] keeps the initial correct for
    // Arabic and any other non-Latin name, where the first UTF-16 code unit can
    // be half of a surrogate pair or a combining mark.
    for (final rune in trimmed.runes) {
      final character = String.fromCharCode(rune).trim();
      if (character.isEmpty) continue;
      return character.toUpperCase();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.loqtaColors;
    final url = imageUrl?.trim() ?? '';
    final initial = initialOf(name);
    final foreground = foregroundColor ?? Colors.white;

    final Widget content;
    if (url.isNotEmpty) {
      content = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // A broken or revoked photo URL must not leave a grey box; fall back to
        // the same initial circle as a missing photo.
        errorBuilder: (context, error, stackTrace) =>
            _fallback(context, palette, initial, foreground),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _fallback(context, palette, initial, foreground);
        },
      );
    } else {
      content = _fallback(context, palette, initial, foreground);
    }

    return ClipOval(
      child: SizedBox(width: size, height: size, child: content),
    );
  }

  Widget _fallback(
    BuildContext context,
    LoqtaPalette palette,
    String? initial,
    Color foreground,
  ) {
    return Container(
      color: backgroundColor ?? LoqtaColors.primary,
      alignment: Alignment.center,
      child: initial != null
          ? Text(
              initial,
              style: TextStyle(
                color: foreground,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w700,
                fontFamily: LoqtaText.family,
                height: 1,
              ),
            )
          : Icon(Icons.person_outline, size: size * 0.55, color: foreground),
    );
  }
}
