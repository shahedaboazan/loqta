import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';

/// A rounded informational card used on several screens.
///
/// Screens 06, 07 and 08 all show the same soft blue panel with a coloured
/// icon on the leading edge and either a bold title plus body copy
/// ("Check your spam folder") or a single muted line ("For your safety,
/// password recovery links expire within 30 minutes").
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.icon,
    this.title,
    this.message,
    this.iconColor = LoqtaColors.primary,
    this.background = LoqtaColors.infoSurface,
    this.borderColor = LoqtaColors.infoBorder,
    this.compact = false,
  });

  final IconData icon;
  final String? title;
  final String? message;
  final Color iconColor;
  final Color background;
  final Color borderColor;

  /// Tighter padding for the single-line variant.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: compact ? 12 : 15,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: const TextStyle(
                      color: LoqtaColors.headingPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: LoqtaText.family,
                    ),
                  ),
                if (message != null) ...[
                  if (title != null) const SizedBox(height: 4),
                  Text(message!, style: LoqtaText.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small green pill badge used above the headings on the verification and
/// reset-password screens ("Almost ready to explore", "Loqta Secure Guard").
class BrandPill extends StatelessWidget {
  const BrandPill({
    super.key,
    required this.label,
    required this.icon,
    this.color = LoqtaColors.primary,
    this.background = LoqtaColors.pillSurface,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              fontFamily: LoqtaText.family,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small muted helper line with a leading icon, used for the trust lines on
/// the sign-in and verification screens.
class IconCaption extends StatelessWidget {
  const IconCaption({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor = LoqtaColors.primary,
    this.textAlign = TextAlign.center,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: textAlign == TextAlign.center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(text: label),
            textAlign: textAlign,
            style: LoqtaText.caption,
          ),
        ),
      ],
    );
  }
}

/// A centred "muted text + green link" row, e.g.
/// "Don't have an account? Create Account".
class InlineLinkRow extends StatelessWidget {
  const InlineLinkRow({
    super.key,
    required this.prompt,
    required this.linkLabel,
    required this.onTap,
  });

  final String prompt;
  final String linkLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Flexible so the row wraps rather than overflowing on narrow screens
        // or when a wider fallback font is substituted.
        Flexible(child: Text(prompt, style: LoqtaText.subtitle)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Text(linkLabel, style: LoqtaText.link),
          ),
        ),
      ],
    );
  }
}
