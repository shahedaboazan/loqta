import 'package:flutter/material.dart';

/// Static content for one onboarding page, transcribed from the approved
/// screenshots `02_onboarding_1.png`, `03_onboarding_2.png` and
/// `04_onboarding_3.png`.
class OnboardingPageContent {
  const OnboardingPageContent({
    required this.title,
    required this.subtitle,
    required this.illustration,
    this.topBadge,
    this.bottomBadge,
    this.features = const [],
    this.featuresPosition = OnboardingFeaturesPosition.aboveTitle,
    this.centerHeader = false,
  });

  final String title;
  final String subtitle;
  final OnboardingIllustration illustration;

  /// Pill in the illustration panel's top-right corner.
  final OnboardingBadge? topBadge;

  /// Pill in the illustration panel's bottom-left corner.
  final OnboardingBadge? bottomBadge;

  /// Supporting cards shown alongside the illustration panel.
  final List<OnboardingFeature> features;

  /// Whether [features] render above the title (page 2 in the reference) or
  /// below the subtitle (page 3).
  final OnboardingFeaturesPosition featuresPosition;

  /// Page 3 centres the logo in the header; pages 1 and 2 align it left.
  final bool centerHeader;
}

/// A pill rendered over the illustration panel, e.g. "BEST DEALS".
class OnboardingBadge {
  const OnboardingBadge({
    required this.icon,
    required this.label,
    this.uppercase = false,
  });

  final IconData icon;
  final String label;

  /// Screens 01 and 02 use an uppercase micro-label ("BEST DEALS"), while
  /// screen 02's "Pass It On" is sentence case.
  final bool uppercase;
}

/// Where the supporting feature cards sit relative to the title block.
enum OnboardingFeaturesPosition { aboveTitle, belowSubtitle }

/// A small supporting card, e.g. "Fair Price / Instant local cash".
class OnboardingFeature {
  const OnboardingFeature({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
}

/// Which artwork to draw for an onboarding page.
enum OnboardingIllustration {
  /// Page 1: "Find What You Need" — camera, headphones, armchair and fridge.
  browse,

  /// Page 2: "Sell or Give" — two people passing a gift box.
  sell,

  /// Page 3: "Simple. Local. Useful." — local peers and an agreed pickup.
  connect,
}

/// The three onboarding pages in design order.
const List<OnboardingPageContent> kOnboardingPages = [
  OnboardingPageContent(
    title: 'Find What You Need',
    subtitle:
        'Discover useful pre-owned items from trusted people in your '
        'local community.',
    illustration: OnboardingIllustration.browse,
    topBadge: OnboardingBadge(
      icon: Icons.sell_outlined,
      label: 'Best Deals',
      uppercase: true,
    ),
    bottomBadge: OnboardingBadge(icon: Icons.public, label: '100% Local Finds'),
  ),
  OnboardingPageContent(
    title: 'Sell or Give',
    subtitle:
        'Give your unused items a new home or sell them simply and '
        'locally.',
    illustration: OnboardingIllustration.sell,
    topBadge: OnboardingBadge(icon: Icons.favorite, label: 'Pass It On'),
    bottomBadge: OnboardingBadge(
      icon: Icons.storefront_outlined,
      label: 'Sell Simply',
    ),
    features: [
      OnboardingFeature(
        icon: Icons.payments_outlined,
        title: 'Fair Price',
        subtitle: 'Instant local cash',
      ),
      OnboardingFeature(
        icon: Icons.redeem_outlined,
        title: 'Zero Cost',
        subtitle: 'Free neighborhood gift',
      ),
    ],
  ),
  OnboardingPageContent(
    title: 'Simple. Local. Useful.',
    subtitle:
        'Connect with people nearby and arrange pickup or delivery '
        'directly through chat.',
    illustration: OnboardingIllustration.connect,
    centerHeader: true,
    featuresPosition: OnboardingFeaturesPosition.belowSubtitle,
    features: [
      OnboardingFeature(icon: Icons.forum_outlined, title: 'Direct Chat'),
      OnboardingFeature(icon: Icons.groups_outlined, title: 'Real Peers'),
      OnboardingFeature(
        icon: Icons.verified_user_outlined,
        title: 'Safe Deals',
      ),
    ],
  ),
];
