import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 100,
    this.circular = false,
    this.borderRadius,
  });

  final double size;
  final bool circular;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/logo.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
        semanticsLabel: 'Loqta',
      ),
    );
  }
}
