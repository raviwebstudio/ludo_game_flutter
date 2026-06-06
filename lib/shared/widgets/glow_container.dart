import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// A container that emits a coloured glow (box‑shadow) behind its child.
class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double blurRadius;
  final double spreadRadius;
  final BorderRadius borderRadius;

  const GlowContainer({
    required this.child,
    this.glowColor = LudoColors.brightBlue,
    this.blurRadius = 16,
    this.spreadRadius = 2,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.5),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }
}
