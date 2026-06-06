import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/models/player.dart';
import '../../../shared/widgets/glass_morphism.dart';

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
    final isPresent = index < players.length;
    final isActive = index == currentPlayerIndex;
    final color = isPresent ? players[index].color : LudoColors.textMedium;

    if (!isPresent) {
      return Opacity(
        opacity: 0.25,
        child: _cardContent(
          color: LudoColors.textMedium,
          name: 'Player ${index + 1}',
          subtitle: '—',
          isActive: false,
        ),
      );
    }

    final homeCount =
        players[index].tokens.where((t) => t.isHome).length;
    final subtitle = '$homeCount/4 Home';

    return _cardContent(
      color: color,
      name: isActive ? 'You' : 'Player ${index + 1}',
      subtitle: subtitle,
      isActive: isActive,
    );
  }

  Widget _cardContent({
    required Color color,
    required String name,
    required String subtitle,
    required bool isActive,
  }) {
    return GlassMorphism(
      opacity: isActive ? 0.12 : 0.06,
      blur: 8,
      borderRadius: BorderRadius.circular(LudoDimensions.radius12),
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
              color: color.withValues(alpha: 0.15),
              border: Border.all(
                color: isActive
                    ? LudoColors.mintGreen
                    : color.withValues(alpha: 0.4),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.person,
                color: color,
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
                    if (isActive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: LudoColors.mintGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'YOU',
                          style: LudoTextStyles.labelSmall.copyWith(
                            color: LudoColors.darkNavyDark,
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
                          color: LudoColors.textLight,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: LudoTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    color: LudoColors.mintGreen.withValues(alpha: 0.7),
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
