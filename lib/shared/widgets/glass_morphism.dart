import 'dart:ui';
import 'package:flutter/material.dart';

/// A frosted‑glass container using [BackdropFilter].
class GlassMorphism extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double blur;
  final BorderRadius borderRadius;
  final EdgeInsets? padding;

  const GlassMorphism({
    required this.child,
    this.opacity = 0.1,
    this.blur = 10.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: opacity * 0.5),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
