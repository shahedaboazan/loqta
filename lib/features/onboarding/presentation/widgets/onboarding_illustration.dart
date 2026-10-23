import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/features/onboarding/domain/entities/onboarding_page_content.dart';

/// Native vector artwork for the onboarding panels.
///
/// The approved screenshots embed bespoke illustration and photography assets
/// that are **not** part of the supplied brand asset set (only
/// `assets/logo.svg` was provided), and `design_spec.md` requires native
/// Flutter widgets rather than screenshots used as backgrounds. These painters
/// therefore reproduce each panel's composition, palette and mood using the
/// approved brand colours. They are deliberate re-creations of the reference
/// artwork, not substitutes for missing approved files.
class OnboardingIllustrationView extends StatelessWidget {
  const OnboardingIllustrationView({super.key, required this.illustration});

  final OnboardingIllustration illustration;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: switch (illustration) {
        OnboardingIllustration.browse => const _BrowsePainter(),
        OnboardingIllustration.sell => const _SellPainter(),
        OnboardingIllustration.connect => const _ConnectPainter(),
      },
      size: Size.infinite,
    );
  }
}

const Color _deepGreen = Color(0xFF00693A);
const Color _midGreen = Color(0xFF1B8A4C);
const Color _teal = Color(0xFF0F7A8C);
const Color _mint = Color(0xFFDFF3E7);

void _roundedBox(Canvas canvas, Rect rect, Color color, {double radius = 12}) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(radius)),
    Paint()..color = color,
  );
}

void _circle(Canvas canvas, Offset center, double radius, Color color) {
  canvas.drawCircle(center, radius, Paint()..color = color);
}

/// Four-point sparkle used as a decorative accent.
void _sparkle(Canvas canvas, Offset center, double size, Color color) {
  final path = Path()
    ..moveTo(center.dx, center.dy - size)
    ..quadraticBezierTo(
      center.dx + size * 0.18,
      center.dy - size * 0.18,
      center.dx + size,
      center.dy,
    )
    ..quadraticBezierTo(
      center.dx + size * 0.18,
      center.dy + size * 0.18,
      center.dx,
      center.dy + size,
    )
    ..quadraticBezierTo(
      center.dx - size * 0.18,
      center.dy + size * 0.18,
      center.dx - size,
      center.dy,
    )
    ..quadraticBezierTo(
      center.dx - size * 0.18,
      center.dy - size * 0.18,
      center.dx,
      center.dy - size,
    );
  canvas.drawPath(path, Paint()..color = color);
}

/// Soft elliptical ground shadow shared by the first two panels.
void _ground(Canvas canvas, Size size, double widthFactor) {
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.85),
      width: size.width * widthFactor,
      height: size.height * 0.07,
    ),
    Paint()..color = LoqtaColors.primary.withValues(alpha: 0.06),
  );
}

/// ---------------------------------------------------------------------------
/// Page 1 — "Find What You Need": camera, headphones, armchair and fridge.
/// ---------------------------------------------------------------------------
class _BrowsePainter extends CustomPainter {
  const _BrowsePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = math.min(w, h);

    _ground(canvas, size, 0.62);

    // Armchair (lower left).
    final seat = Rect.fromLTWH(w * 0.13, h * 0.60, w * 0.22, h * 0.22);
    _roundedBox(canvas, seat, _deepGreen, radius: unit * 0.06);
    _roundedBox(
      canvas,
      Rect.fromLTWH(w * 0.16, h * 0.66, w * 0.16, h * 0.13),
      _midGreen,
      radius: unit * 0.04,
    );
    // Legs.
    final leg = Paint()
      ..color = _teal
      ..strokeWidth = unit * 0.014
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.18, h * 0.82),
      Offset(w * 0.16, h * 0.89),
      leg,
    );
    canvas.drawLine(
      Offset(w * 0.30, h * 0.82),
      Offset(w * 0.32, h * 0.89),
      leg,
    );

    // Camera (right).
    final body = Rect.fromLTWH(w * 0.53, h * 0.28, w * 0.33, h * 0.25);
    _roundedBox(canvas, body, _deepGreen, radius: unit * 0.045);
    _roundedBox(
      canvas,
      Rect.fromLTWH(w * 0.61, h * 0.23, w * 0.11, h * 0.06),
      _deepGreen,
      radius: unit * 0.018,
    );
    _circle(canvas, Offset(w * 0.695, h * 0.405), unit * 0.075, _mint);
    _circle(canvas, Offset(w * 0.695, h * 0.405), unit * 0.055, _midGreen);
    _circle(canvas, Offset(w * 0.695, h * 0.405), unit * 0.032, _teal);
    _circle(canvas, Offset(w * 0.59, h * 0.325), unit * 0.02, Colors.white);

    // Headphones (upper left).
    canvas.drawArc(
      Rect.fromLTWH(w * 0.05, h * 0.14, w * 0.40, h * 0.40),
      math.pi * 1.06,
      math.pi * 0.88,
      false,
      Paint()
        ..color = _midGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.042
        ..strokeCap = StrokeCap.round,
    );
    _roundedBox(
      canvas,
      Rect.fromLTWH(w * 0.045, h * 0.37, w * 0.08, h * 0.15),
      _midGreen,
      radius: unit * 0.035,
    );
    _roundedBox(
      canvas,
      Rect.fromLTWH(w * 0.345, h * 0.37, w * 0.08, h * 0.15),
      _midGreen,
      radius: unit * 0.035,
    );

    // Fridge / cabinet (lower right).
    final fridge = Rect.fromLTWH(w * 0.63, h * 0.58, w * 0.20, h * 0.27);
    _roundedBox(canvas, fridge, Colors.white, radius: unit * 0.028);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fridge, Radius.circular(unit * 0.028)),
      Paint()
        ..color = _mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.011,
    );
    _roundedBox(
      canvas,
      Rect.fromLTWH(w * 0.655, h * 0.62, w * 0.045, h * 0.075),
      _midGreen,
      radius: unit * 0.011,
    );
    _roundedBox(
      canvas,
      Rect.fromLTWH(w * 0.71, h * 0.62, w * 0.045, h * 0.075),
      _teal,
      radius: unit * 0.011,
    );
    _roundedBox(
      canvas,
      Rect.fromLTWH(w * 0.655, h * 0.73, w * 0.10, h * 0.06),
      const Color(0xFF9BCB5E),
      radius: unit * 0.011,
    );
    canvas.drawLine(
      Offset(w * 0.645, h * 0.715),
      Offset(w * 0.815, h * 0.715),
      Paint()
        ..color = _mint
        ..strokeWidth = unit * 0.009,
    );

    // Decorative sparkles.
    _sparkle(canvas, Offset(w * 0.45, h * 0.20), unit * 0.045, _midGreen);
    _sparkle(
      canvas,
      Offset(w * 0.90, h * 0.50),
      unit * 0.032,
      LoqtaColors.accentCyan,
    );
    _sparkle(canvas, Offset(w * 0.10, h * 0.28), unit * 0.026, _midGreen);
    _sparkle(
      canvas,
      Offset(w * 0.47, h * 0.50),
      unit * 0.02,
      LoqtaColors.accentCyan,
    );
  }

  @override
  bool shouldRepaint(covariant _BrowsePainter oldDelegate) => false;
}

/// ---------------------------------------------------------------------------
/// Page 2 — "Sell or Give": two neighbours passing a gift box.
/// ---------------------------------------------------------------------------
class _SellPainter extends CustomPainter {
  const _SellPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = math.min(w, h);

    _ground(canvas, size, 0.66);

    // Left neighbour.
    _circle(
      canvas,
      Offset(w * 0.25, h * 0.34),
      unit * 0.082,
      const Color(0xFF23201F),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.25, h * 0.45)
        ..quadraticBezierTo(w * 0.11, h * 0.53, w * 0.10, h * 0.74)
        ..lineTo(w * 0.40, h * 0.74)
        ..quadraticBezierTo(w * 0.39, h * 0.53, w * 0.25, h * 0.45)
        ..close(),
      Paint()..color = _midGreen,
    );

    // Right neighbour.
    _circle(
      canvas,
      Offset(w * 0.75, h * 0.34),
      unit * 0.082,
      const Color(0xFF23201F),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.75, h * 0.45)
        ..quadraticBezierTo(w * 0.89, h * 0.53, w * 0.90, h * 0.74)
        ..lineTo(w * 0.60, h * 0.74)
        ..quadraticBezierTo(w * 0.61, h * 0.53, w * 0.75, h * 0.45)
        ..close(),
      Paint()..color = _teal,
    );

    // Arms reaching for the gift.
    final arm = Paint()
      ..color = _midGreen
      ..strokeWidth = unit * 0.048
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.34, h * 0.58),
      Offset(w * 0.45, h * 0.615),
      arm,
    );
    canvas.drawLine(
      Offset(w * 0.66, h * 0.58),
      Offset(w * 0.55, h * 0.615),
      Paint()
        ..color = _teal
        ..strokeWidth = unit * 0.048
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Gift box.
    _roundedBox(
      canvas,
      Rect.fromLTWH(w * 0.40, h * 0.57, w * 0.20, h * 0.17),
      LoqtaColors.secondaryGreen,
      radius: unit * 0.02,
    );
    _roundedBox(
      canvas,
      Rect.fromLTWH(w * 0.375, h * 0.535, w * 0.25, h * 0.06),
      _midGreen,
      radius: unit * 0.02,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.487, h * 0.535, w * 0.026, h * 0.205),
      Paint()..color = _mint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.465, h * 0.515),
        width: w * 0.06,
        height: h * 0.05,
      ),
      Paint()..color = _midGreen,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.535, h * 0.515),
        width: w * 0.06,
        height: h * 0.05,
      ),
      Paint()..color = _midGreen,
    );

    // Confetti.
    _circle(canvas, Offset(w * 0.14, h * 0.22), unit * 0.017, _midGreen);
    _circle(
      canvas,
      Offset(w * 0.86, h * 0.26),
      unit * 0.021,
      LoqtaColors.accentCyan,
    );
    _sparkle(
      canvas,
      Offset(w * 0.30, h * 0.18),
      unit * 0.038,
      LoqtaColors.accentCyan,
    );
    _sparkle(canvas, Offset(w * 0.70, h * 0.17), unit * 0.028, _midGreen);
  }

  @override
  bool shouldRepaint(covariant _SellPainter oldDelegate) => false;
}

/// ---------------------------------------------------------------------------
/// Page 3 — "Simple. Local. Useful.": two local peers and an agreed pickup.
///
/// The reference centres a circular photograph of two neighbours meeting. No
/// photography asset was supplied with the approved set, so the circle is
/// drawn as a brand-tinted portrait medallion in the same position and size.
/// ---------------------------------------------------------------------------
class _ConnectPainter extends CustomPainter {
  const _ConnectPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = math.min(w, h);

    // Portrait medallion.
    final center = Offset(w * 0.5, h * 0.52);
    final radius = unit * 0.36;
    _circle(canvas, center, radius, _mint);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _midGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.012,
    );

    // Two neighbours facing each other, drawn as head + shoulders so the
    // gesture reads clearly at a glance.
    void person(double dxFactor, Color color, double scale) {
      final headCenter = center.translate(radius * dxFactor, -radius * 0.22);
      final headRadius = radius * 0.20 * scale;
      _circle(canvas, headCenter, headRadius, color);

      // Shoulders: a rounded block below the head, clipped to the disc.
      final shoulderTop = headCenter.dy + headRadius * 1.05;
      final shoulderPath = Path()
        ..moveTo(center.dx + radius * dxFactor - headRadius * 2.0, radius + h)
        ..lineTo(
          center.dx + radius * dxFactor - headRadius * 2.0,
          shoulderTop + headRadius * 0.5,
        )
        ..quadraticBezierTo(
          center.dx + radius * dxFactor - headRadius * 2.0,
          shoulderTop,
          center.dx + radius * dxFactor,
          shoulderTop,
        )
        ..quadraticBezierTo(
          center.dx + radius * dxFactor + headRadius * 2.0,
          shoulderTop,
          center.dx + radius * dxFactor + headRadius * 2.0,
          shoulderTop + headRadius * 0.5,
        )
        ..lineTo(center.dx + radius * dxFactor + headRadius * 2.0, radius + h)
        ..close();
      canvas.drawPath(shoulderPath, Paint()..color = color);
    }

    // Draw the far figure first so the near one overlaps it.
    person(0.34, _midGreen, 0.92);
    person(-0.32, _teal, 1.0);

    // Chat bubble between them.
    final bubble = Rect.fromCenter(
      center: center.translate(0, radius * 0.62),
      width: radius * 1.15,
      height: radius * 0.52,
    );
    _roundedBox(canvas, bubble, Colors.white, radius: radius * 0.16);
    final line = Paint()
      ..color = _mint
      ..strokeWidth = unit * 0.016
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 2; i++) {
      final y = bubble.top + bubble.height * (0.36 + i * 0.28);
      canvas.drawLine(
        Offset(bubble.left + bubble.width * 0.16, y),
        Offset(bubble.left + bubble.width * (i == 0 ? 0.84 : 0.62), y),
        line,
      );
    }

    // Accent sparkles.
    _sparkle(canvas, Offset(w * 0.13, h * 0.16), unit * 0.032, _midGreen);
    _sparkle(
      canvas,
      Offset(w * 0.88, h * 0.20),
      unit * 0.028,
      LoqtaColors.accentCyan,
    );
  }

  @override
  bool shouldRepaint(covariant _ConnectPainter oldDelegate) => false;
}
