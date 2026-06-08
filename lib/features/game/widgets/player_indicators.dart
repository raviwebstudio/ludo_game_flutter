import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/models/player.dart';

class PlayerTheme {
  final Color background;
  final Color border;
  final Color text;

  const PlayerTheme({
    required this.background,
    required this.border,
    required this.text,
  });
}

PlayerTheme getPlayerTheme(Color color) {
  if (color == LudoColors.redToken) {
    return const PlayerTheme(
      background: Color(0xFFFFE5E5),
      border: Color(0xFFE53935),
      text: Color(0xFFB71C1C),
    );
  } else if (color == LudoColors.greenToken) {
    return const PlayerTheme(
      background: Color(0xFFE8F5E9),
      border: Color(0xFF43A047),
      text: Color(0xFF1B5E20),
    );
  } else if (color == LudoColors.blueToken) {
    return const PlayerTheme(
      background: Color(0xFFE3F2FD),
      border: Color(0xFF1E88E5),
      text: Color(0xFF0D47A1),
    );
  } else if (color == LudoColors.yellowToken) {
    return const PlayerTheme(
      background: Color(0xFFFFF8E1),
      border: Color(0xFFFFB300),
      text: Color(0xFFE65100),
    );
  }

  return const PlayerTheme(
    background: Color(0xFFF2F2F2),
    border: Color(0xFF8C8C8C),
    text: Color(0xFF333333),
  );
}

/// A row of player info cards — positioned at top / bottom of the board.
class PlayerIndicators extends StatelessWidget {
  final List<Player> players;
  final int currentPlayerIndex;
  final int leftIndex;
  final int rightIndex;

  const PlayerIndicators({
    required this.players,
    required this.currentPlayerIndex,
    required this.leftIndex,
    required this.rightIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCard(leftIndex)),
        const SizedBox(width: 12),
        Expanded(child: _buildCard(rightIndex)),
      ],
    );
  }

  Widget _buildCard(int index) {
    final playerIndex = players.indexWhere((p) => p.id == index);
    final isPresent = playerIndex != -1;
    final isActive = isPresent && playerIndex == currentPlayerIndex;

    if (!isPresent) {
      return Opacity(
        opacity: 0.25,
        child: _cardContent(
          theme: const PlayerTheme(
            background: Color(0xFFF2F2F2),
            border: Color(0xFF8C8C8C),
            text: Color(0xFF333333),
          ),
          name: 'Player ${index + 1}',
          subtitle: '—',
          isActive: false,
          isYou: false,
        ),
      );
    }

    final player = players[playerIndex];
    final theme = getPlayerTheme(player.color);
    final isYou = player.id == 0 || player.name.toLowerCase() == 'you';
    final homeCount = player.tokens.where((t) => t.isHome).length;
    final subtitle = '$homeCount/4 Home';

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: isActive ? 1.05 : 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: _cardContent(
        theme: theme,
        name: player.name,
        subtitle: subtitle,
        isActive: isActive,
        isYou: isYou,
      ),
    );
  }

  Widget _cardContent({
    required PlayerTheme theme,
    required String name,
    required String subtitle,
    required bool isActive,
    required bool isYou,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? theme.border : theme.border.withOpacity(0.4),
          width: isActive ? 2.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          if (isActive)
            BoxShadow(
              color: theme.border.withOpacity(0.35),
              blurRadius: 10,
              spreadRadius: 2,
            ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: LudoDimensions.spacing12,
        vertical: LudoDimensions.spacing8,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: theme.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.person,
                color: theme.border,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (isYou) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: ShapeDecoration(
                          color: theme.border,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'YOU',
                          style: LudoTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: LudoTextStyles.labelSmall.copyWith(
                          color: theme.text,
                          fontWeight:
                              isActive ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: LudoTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    color: theme.text.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
