import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';

/// The onboarding progress indicator.
///
/// Matches screenshots 02–04: the active page is a wide green pill, inactive
/// pages are small pale dots.
class PageIndicators extends StatelessWidget {
  const PageIndicators({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 5,
          width: isActive ? 22 : 6,
          decoration: BoxDecoration(
            color: isActive
                ? LoqtaColors.primary
                : LoqtaColors.progressInactive,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
