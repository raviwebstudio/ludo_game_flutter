import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ludo_game/core/constants/colors.dart';
import 'package:ludo_game/core/constants/dimensions.dart';
import 'package:ludo_game/core/constants/text_styles.dart';
import 'package:ludo_game/core/services/sound_manager.dart';
import 'package:ludo_game/shared/widgets/glass_morphism.dart';
import 'package:ludo_game/shared/widgets/gradient_button.dart';
import '../../../presentation/bloc/game_bloc.dart';
import '../widgets/board_container.dart';
import '../widgets/dice_widget.dart';
import '../widgets/game_board.dart';
import '../widgets/player_indicators.dart';
import '../widgets/turn_indicator.dart';

/// The main premium Game Play screen for Ludo Elite.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  static const double _maxContentWidth = 420;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [LudoColors.darkNavyDark, LudoColors.darkNavy],
          ),
        ),
        child: BlocBuilder<GameBloc, GameState>(
          builder: (context, state) {
            if (state.players.isEmpty) {
              return const SafeArea(
                child: Center(
                  child: CircularProgressIndicator(
                    color: LudoColors.brightBlue,
                  ),
                ),
              );
            }

            return Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LudoDimensions.spacing16,
                      vertical: LudoDimensions.spacing8,
                    ),
                    child: Column(
                      children: [
                        // Top Bar
                        _buildTopBar(context),
                        const Spacer(),

                        // Top Players Indicators (0 and 1)
                        PlayerIndicators(
                          players: state.players,
                          currentPlayerIndex: state.currentPlayerIndex,
                          leftIndex: 0,
                          rightIndex: 1,
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

                        const SizedBox(height: LudoDimensions.spacing16),

                        // Game Board Container
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _maxContentWidth,
                            ),
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: BoardContainer(
                                child: GameBoard(
                                  players: state.players,
                                  currentPlayerIndex: state.currentPlayerIndex,
                                  validTokens: state.validTokens,
                                  captureEffect: state.captureEffect,
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),

                        const SizedBox(height: LudoDimensions.spacing16),

                        // Bottom Players Indicators (3 and 2)
                        PlayerIndicators(
                          players: state.players,
                          currentPlayerIndex: state.currentPlayerIndex,
                          leftIndex: 3,
                          rightIndex: 2,
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                        const Spacer(),

                        // Turn Indicator Banner
                        TurnIndicator(
                          playerIndex: state.currentPlayerIndex,
                          playerColor: state.currentPlayerIndex < state.players.length
                              ? state.players[state.currentPlayerIndex].color
                              : LudoColors.purple,
                          isGameOver: state.isGameOver,
                        )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .shimmer(delay: 500.ms, duration: 1000.ms, color: LudoColors.mintGreen.withValues(alpha: 0.3)),

                        const SizedBox(height: LudoDimensions.spacing16),

                        // Large Central Dice
                        _buildCentralDice(context, state),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),

                // Game Over Overlay
                if (state.isGameOver)
                  _buildGameOverOverlay(context, state)
                      .animate()
                      .fadeIn(duration: 500.ms),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            // Confirm exit dialog
            showDialog(
              context: context,
              builder: (context) => _buildExitDialog(context),
            );
          },
          icon: const Icon(Icons.arrow_back_ios, color: LudoColors.textLight),
        ),
        Text(
          'LUDO ELITE',
          style: LudoTextStyles.displayMedium.copyWith(
            fontSize: 20,
            letterSpacing: 1.5,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
          icon: const Icon(Icons.settings, color: LudoColors.textLight),
        ),
      ],
    );
  }

  Widget _buildCentralDice(BuildContext context, GameState state) {
    final activePlayerIndex = state.currentPlayerIndex;
    final isPresent = activePlayerIndex < state.players.length;
    final canRoll = isPresent && state.canRollDice && !state.isMoving;
    final activeColor = isPresent
        ? state.players[activePlayerIndex].color
        : LudoColors.purple;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DiceWidget(
          value: state.diceValue,
          enabled: canRoll,
          isActivePlayer: canRoll,
          activeColor: activeColor,
          size: 88,
          onRoll: () {
            final completer = Completer<int?>();
            context.read<GameBloc>().add(RollDice(resultCompleter: completer));
            return completer.future;
          },
        ),
        const SizedBox(height: 8),
        Text(
          canRoll ? 'TAP TO ROLL' : 'WAITING FOR TURN',
          style: LudoTextStyles.labelSmall.copyWith(
            color: canRoll ? LudoColors.mintGreen : LudoColors.textMedium,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ).animate(target: canRoll ? 1.0 : 0.0)
            .fadeIn(duration: 200.ms)
            .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.5)),
      ],
    );
  }

  Widget _buildExitDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassMorphism(
        opacity: 0.15,
        blur: 16,
        borderRadius: BorderRadius.circular(LudoDimensions.radius24),
        padding: const EdgeInsets.all(LudoDimensions.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: LudoColors.redToken,
              size: 48,
            ).animate().shake(duration: 500.ms),
            const SizedBox(height: 16),
            Text(
              'Quit Game?',
              style: LudoTextStyles.headlineSmall.copyWith(color: LudoColors.textLight),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to end this game? Your progress will be lost.',
              textAlign: TextAlign.center,
              style: LudoTextStyles.bodyMedium.copyWith(color: LudoColors.textMedium),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: LudoTextStyles.labelSmall.copyWith(
                        color: LudoColors.textMedium,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    label: 'Quit',
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Exit Game Screen
                    },
                    colors: const [LudoColors.redToken, Color(0xFFC0392B)],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, GameState state) {
    final duration = DateTime.now().difference(state.startTime ?? DateTime.now());
    final activePlayerIndex = state.currentPlayerIndex;
    final winnerColor = activePlayerIndex < state.players.length
        ? state.players[activePlayerIndex].color
        : LudoColors.mintGreen;

    // Trigger victory sound (we can just call the sound manager here, since build is called once when state updates)
    SoundManager().playSound(SoundType.victory);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(LudoDimensions.spacing24),
          child: GlassMorphism(
            opacity: 0.1,
            blur: 20,
            borderRadius: BorderRadius.circular(LudoDimensions.radius24),
            padding: const EdgeInsets.all(LudoDimensions.spacing32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cup icon with glowing animations
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: winnerColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: winnerColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: winnerColor.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: winnerColor,
                    size: 48,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 800.ms)
                    .shimmer(duration: 1500.ms, color: Colors.white),

                const SizedBox(height: 24),

                Text(
                  'VICTORY!',
                  style: LudoTextStyles.displayMedium.copyWith(
                    color: winnerColor,
                    letterSpacing: 2.0,
                  ),
                ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.bounceOut),

                const SizedBox(height: 12),

                Text(
                  'Player ${activePlayerIndex + 1} takes the crown!',
                  textAlign: TextAlign.center,
                  style: LudoTextStyles.headlineSmall.copyWith(
                    color: LudoColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 24),

                // Stats row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(LudoDimensions.radius16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'TIME',
                            style: LudoTextStyles.labelSmall.copyWith(color: LudoColors.textMedium),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${duration.inMinutes}m ${duration.inSeconds % 60}s',
                            style: LudoTextStyles.bodyLarge.copyWith(
                              color: LudoColors.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      Column(
                        children: [
                          Text(
                            'REWARD',
                            style: LudoTextStyles.labelSmall.copyWith(color: LudoColors.textMedium),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on, color: LudoColors.gold, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '+500',
                                style: LudoTextStyles.bodyLarge.copyWith(
                                  color: LudoColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                GradientButton(
                  label: 'PLAY AGAIN',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  colors: const [LudoColors.purple, LudoColors.purpleLight],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
