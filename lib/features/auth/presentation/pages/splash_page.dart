import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/brand_logo.dart';

/// Shown while the persisted Supabase session and the onboarding flag are
/// restored.
///
/// Built from `design_drafts/screens/01_splash.png`: a soft mint-to-cyan
/// gradient wash, the official logo on a white disc slightly above the optical
/// centre, and a small indeterminate green progress ring below it.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFC8EAD6), // أخضر نعناعي أكثر وضوحاً
              Color(0xFFF0F9F4), // درجة فاتحة ناعمة بدلاً من الأبيض الصريح
              Color(0xFFD4E4F7), // أزرق هادئ واضحة معالمه
              Color(0xFFBFE3CC), // أخضر عميق متناسق للتدرج السفلي
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /* Container(
                width: 152,
                height: 152,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const BrandLogo(size: 104, circular: true),
              ), */
              const BrandLogo(size: 180, circular: false),
              const SizedBox(height: 84),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    LoqtaColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
