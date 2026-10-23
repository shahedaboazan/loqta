import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/features/onboarding/domain/entities/onboarding_page_content.dart';

/// The supporting cards shown on onboarding pages 2 and 3.
///
/// Page 2 uses two wide horizontal cards with a title and a muted subtitle
/// ("Fair Price / Instant local cash"); page 3 uses three narrow cards that
/// stack the icon above the label ("Direct Chat").
class OnboardingFeatureCards extends StatelessWidget {
  const OnboardingFeatureCards({
    super.key,
    required this.features,
    required this.vertical,
  });

  final List<OnboardingFeature> features;

  /// Page 3 stacks icon above title; page 2 places them side by side.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight lets the cards stretch to an equal height while the Row
    // is still bounded, which a bare Expanded would not.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < features.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _FeatureCard(feature: features[i], vertical: vertical),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature, required this.vertical});

  final OnboardingFeature feature;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: LoqtaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LoqtaColors.border),
      ),
      child: vertical
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(feature.icon, size: 21, color: LoqtaColors.primary),
                const SizedBox(height: 8),
                Text(
                  feature.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: LoqtaColors.headingPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: LoqtaText.family,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Icon(feature.icon, size: 21, color: LoqtaColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        feature.title,
                        style: const TextStyle(
                          color: LoqtaColors.headingPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: LoqtaText.family,
                        ),
                      ),
                      if (feature.subtitle != null)
                        Text(
                          feature.subtitle!,
                          style: const TextStyle(
                            color: LoqtaColors.textSecondary,
                            fontSize: 11,
                            height: 1.3,
                            fontFamily: LoqtaText.family,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
