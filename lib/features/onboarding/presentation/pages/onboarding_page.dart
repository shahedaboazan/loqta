import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/brand_logo.dart';
import 'package:loqta/core/widgets/loqta_button.dart';
import 'package:loqta/core/widgets/page_indicators.dart';
import 'package:loqta/features/onboarding/domain/entities/onboarding_page_content.dart';
import 'package:loqta/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:loqta/features/onboarding/presentation/widgets/onboarding_feature_cards.dart';
import 'package:loqta/features/onboarding/presentation/widgets/onboarding_illustration.dart';

/// The three-page onboarding flow, rebuilt from screenshots 02, 03 and 04.
///
/// The page is stateless: which page is shown comes entirely from
/// [OnboardingBloc], and the bloc persists the "onboarding completed" flag and
/// flips to `completed`, which makes the existing auth gate render the existing
/// sign-in screen. Nothing is pushed onto the navigator, so the flow cannot
/// double-navigate.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardingBloc>().state;
    final pageIndex = state.pageIndex.clamp(0, kOnboardingPages.length - 1);
    final page = kOnboardingPages[pageIndex];
    final isLastPage = pageIndex == kOnboardingPages.length - 1;

    // Consume the system back gesture to step back through the flow. On the
    // first page the reference designs show no back affordance, so back is
    // allowed to leave the app as usual.
    return PopScope(
      canPop: pageIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.read<OnboardingBloc>().add(const OnboardingBackRequested());
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF7FCF9)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _Header(page: page),
                // The panel and the copy scroll; the primary action stays
                // pinned below so "Next" / "Get Started" is always reachable,
                // including on short viewports where the full column would
                // not fit.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Size the illustration panel from the width so it keeps
                      // a sane proportion, capped so it cannot dominate a tall
                      // screen and shrink to stay usable on a short one.
                      final availableWidth = constraints.maxWidth.isFinite
                          ? constraints.maxWidth
                          : MediaQuery.sizeOf(context).width;
                      final panelWidth =
                          availableWidth - LoqtaSpacing.gutter * 2;
                      final panelHeight = (panelWidth * 0.95).clamp(
                        150.0,
                        340.0,
                      );

                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          // Fill the viewport and centre the column, so a
                          // short page has no dead gap above the pinned
                          // button. When the content is taller than the
                          // viewport the constraint is satisfied naturally and
                          // the view scrolls.
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: SizedBox(
                                  width: panelWidth,
                                  height: panelHeight,
                                  child: _IllustrationPanel(page: page),
                                ),
                              ),
                              if (page.features.isNotEmpty &&
                                  page.featuresPosition ==
                                      OnboardingFeaturesPosition
                                          .aboveTitle) ...[
                                const SizedBox(height: 18),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: LoqtaSpacing.gutter,
                                  ),
                                  child: OnboardingFeatureCards(
                                    features: page.features,
                                    vertical: false,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: LoqtaSpacing.gutter,
                                ),
                                child: Text(
                                  page.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: LoqtaColors.headingPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    height: 1.2,
                                    fontFamily: LoqtaText.family,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                ),
                                child: Text(
                                  page.subtitle,
                                  textAlign: TextAlign.center,
                                  style: LoqtaText.subtitle,
                                ),
                              ),
                              if (page.features.isNotEmpty &&
                                  page.featuresPosition ==
                                      OnboardingFeaturesPosition
                                          .belowSubtitle) ...[
                                const SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: LoqtaSpacing.gutter,
                                  ),
                                  child: OnboardingFeatureCards(
                                    features: page.features,
                                    vertical: true,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              PageIndicators(
                                count: kOnboardingPages.length,
                                currentIndex: pageIndex,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    LoqtaSpacing.gutter,
                    0,
                    LoqtaSpacing.gutter,
                    20,
                  ),
                  child: LoqtaButton(
                    label: isLastPage ? 'Get Started' : 'Next',
                    onPressed: () => context.read<OnboardingBloc>().add(
                      const OnboardingNextRequested(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo plus the "Skip" affordance.
///
/// Screens 01 and 02 align the logo to the leading edge; screen 03 centres
/// it. Either way "Skip" sits on the trailing edge.
class _Header extends StatelessWidget {
  const _Header({required this.page});

  final OnboardingPageContent page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LoqtaSpacing.gutter,
        8,
        LoqtaSpacing.gutter - 8,
        4,
      ),
      child: Row(
        children: [
          if (page.centerHeader) const Spacer(),
          const BrandLogo(size: 38),
          const Spacer(),
          TextButton(
            onPressed: () => context.read<OnboardingBloc>().add(
              const OnboardingSkipRequested(),
            ),
            style: TextButton.styleFrom(
              foregroundColor: LoqtaColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(48, 44),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: LoqtaText.family,
              ),
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

/// The rounded mint illustration panel with its floating badges.
class _IllustrationPanel extends StatelessWidget {
  const _IllustrationPanel({required this.page});

  final OnboardingPageContent page;

  @override
  Widget build(BuildContext context) {
    final topBadge = page.topBadge;
    final bottomBadge = page.bottomBadge;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF6F9), Color(0xFFEFF9F3)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: OnboardingIllustrationView(
                illustration: page.illustration,
              ),
            ),
          ),
          if (topBadge != null)
            Positioned(
              top: 12,
              right: 12,
              child: _PanelBadge(
                badge: topBadge,
                background: Colors.white,
                foreground: LoqtaColors.primary,
              ),
            ),
          if (bottomBadge != null)
            Positioned(
              bottom: 12,
              left: 12,
              child: _PanelBadge(
                badge: bottomBadge,
                background: Colors.white,
                foreground: LoqtaColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

/// The pill rendered over the illustration panel, e.g. "BEST DEALS".
class _PanelBadge extends StatelessWidget {
  const _PanelBadge({
    required this.badge,
    required this.background,
    required this.foreground,
  });

  final OnboardingBadge badge;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 13, color: foreground),
          const SizedBox(width: 6),
          Text(
            badge.uppercase ? badge.label.toUpperCase() : badge.label,
            style: TextStyle(
              color: foreground,
              fontSize: badge.uppercase ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: badge.uppercase ? 0.4 : 0,
              fontFamily: LoqtaText.family,
            ),
          ),
        ],
      ),
    );
  }
}
