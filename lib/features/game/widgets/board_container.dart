import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';

/// A dark rounded container that wraps the game board with a subtle glow.
class BoardContainer extends StatelessWidget {
  final Widget child;

  const BoardContainer({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFE),
        borderRadius: BorderRadius.circular(LudoDimensions.radius24),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: LudoColors.purple.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}
