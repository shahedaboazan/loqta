import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/brand_logo.dart';
import 'package:loqta/core/widgets/loqta_button.dart';

/// Shown when the app cannot start, for instance because Supabase could not
/// be initialized.
///
/// Startup problems are shown instead of being swallowed: the user sees what
/// happened and can try again, rather than staring at a blank screen or at
/// the splash screen forever.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({
    super.key,
    required this.error,
    required this.onRetry,
  });

  /// What went wrong. The technical detail is shown small, under the
  /// message, so it can be reported without guessing.
  final Object error;

  /// Starts the app again.
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loqta',
      debugShowCheckedModeBanner: false,
      theme: LoqtaTheme.light,
      home: StartupFailurePage(error: error, onRetry: onRetry),
    );
  }
}

/// The failure screen itself.
class StartupFailurePage extends StatelessWidget {
  const StartupFailurePage({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: LoqtaSpacing.gutter,
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLogo(size: 72),
                const SizedBox(height: 24),
                Text(
                  'Loqta could not start',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: LoqtaColors.headingPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: LoqtaText.family,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: LoqtaText.subtitle,
                ),
                const SizedBox(height: 16),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: LoqtaColors.textSecondary,
                    fontSize: 12,
                    fontFamily: LoqtaText.family,
                  ),
                ),
                const SizedBox(height: 28),
                LoqtaButton(label: 'Try again', onPressed: () => onRetry()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
