import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

/// "YOUR TURN" / "PLAYER X'S TURN" banner with decorative lines.
class TurnIndicator extends StatelessWidget {
  final int playerIndex;
  final Color playerColor;
  final bool isGameOver;

  const TurnIndicator({
    required this.playerIndex,
    required this.playerColor,
    this.isGameOver = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final text = isGameOver
        ? 'PLAYER ${playerIndex + 1} WINS!'
        : 'YOUR TURN';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: child,
      ),
      child: Padding(
        key: ValueKey('$playerIndex-$isGameOver'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left line
            Expanded(
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      LudoColors.mintGreen.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              text,
              style: LudoTextStyles.headlineXS.copyWith(
                color: LudoColors.mintGreen,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 16),
            // Right line
            Expanded(
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      LudoColors.mintGreen.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
