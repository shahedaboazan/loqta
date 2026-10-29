import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';

/// The full-width green primary action used on every screen, with the trailing
/// arrow shown in the approved references (05–09) and the onboarding flow.
class LoqtaButton extends StatelessWidget {
  const LoqtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.showArrow = true,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Renders the trailing arrow. The reference designs show it everywhere
  /// except the onboarding "Next"/"Get Started" buttons, which already carry
  /// it, so callers control it explicitly.
  final bool showArrow;

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: LoqtaColors.primary,
          disabledBackgroundColor: LoqtaColors.primary.withValues(alpha: 0.12),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LoqtaSpacing.radiusButton),
          ),
          textStyle: LoqtaText.button,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  if (showArrow) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward, size: 19),
                  ],
                ],
              ),
      ),
    );
  }
}

/// A muted centred link used below the primary action, e.g. "Back to Sign In".
class MutedTextLink extends StatelessWidget {
  const MutedTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.showBackArrow = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool showBackArrow;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: LoqtaColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(48, 44),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: LoqtaText.family,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBackArrow) ...[
            const Icon(Icons.arrow_back, size: 15),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
    );
  }
}

/// A hairline divider with breathing room, as used on the sign-in and
/// reset-password screens.
class SoftDivider extends StatelessWidget {
  const SoftDivider({super.key, this.verticalPadding = 18});

  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: const Divider(height: 1, color: LoqtaColors.border),
    );
  }
}
