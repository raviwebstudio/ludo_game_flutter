import 'package:flutter/material.dart';
import '../../../core/constants/text_styles.dart';

/// Dynamic player name turn banner with decorative lines colored by the player's color.
class TurnIndicator extends StatelessWidget {
  final int playerIndex;
  final String playerName;
  final Color playerColor;
  final bool isGameOver;

  const TurnIndicator({
    required this.playerIndex,
    required this.playerName,
    required this.playerColor,
    this.isGameOver = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final text = isGameOver
        ? '${playerName.toUpperCase()} WINS!'
        : "${playerName.toUpperCase()}'S TURN";

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
                      playerColor.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              text,
              style: LudoTextStyles.headlineXS.copyWith(
                color: playerColor,
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
                      playerColor.withValues(alpha: 0.6),
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
