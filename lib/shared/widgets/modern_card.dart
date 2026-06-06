import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

/// A dark card with subtle shadow — the default surface for content sections.
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final double borderRadius;

  const ModernCard({
    required this.child,
    this.padding = const EdgeInsets.all(LudoDimensions.spacing16),
    this.onTap,
    this.backgroundColor = LudoColors.darkNavyLight,
    this.borderRadius = LudoDimensions.radius20,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: LudoColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
