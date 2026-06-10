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
import 'package:ludo_game/domain/models/player.dart';
import '../widgets/board_container.dart';
import '../widgets/dice_widget.dart';
import '../widgets/game_board.dart';
import '../widgets/player_indicators.dart';
import '../widgets/turn_indicator.dart';

/// The main premium Game Play screen for Ludo Elite.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const double _maxContentWidth = 420;
  bool _isAutoplay = false;
  Timer? _autoplayTimer;

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    super.dispose();
  }

  void _triggerAutoplayAction(GameState state) {
    if (!_isAutoplay || state.isGameOver || state.isMoving) {
      _autoplayTimer?.cancel();
      _autoplayTimer = null;
      return;
    }

    if (_autoplayTimer != null) return; // Already scheduled

    if (state.canRollDice) {
      _autoplayTimer = Timer(const Duration(milliseconds: 800), () {
        _autoplayTimer = null;
        if (!mounted || !_isAutoplay) return;
        final currentState = context.read<GameBloc>().state;
        if (currentState.canRollDice && !currentState.isMoving && !currentState.isGameOver) {
          final completer = Completer<int?>();
          context.read<GameBloc>().add(RollDice(resultCompleter: completer));
        }
      });
    } else if (state.validTokens.isNotEmpty) {
      _autoplayTimer = Timer(const Duration(milliseconds: 800), () {
        _autoplayTimer = null;
        if (!mounted || !_isAutoplay) return;
        final currentState = context.read<GameBloc>().state;
        if (currentState.validTokens.isNotEmpty && !currentState.isMoving && !currentState.isGameOver) {
          final chosenToken = _chooseBestToken(currentState);
          context.read<GameBloc>().add(SelectToken(chosenToken));
        }
      });
    }
  }

  Token _chooseBestToken(GameState state) {
    final currentPlayerIndex = state.currentPlayerIndex;
    final currentPlayer = state.players[currentPlayerIndex];
    final gameRepository = context.read<GameBloc>().gameRepository;
    
    Token? bestToken;
    int bestScore = -1000;

    for (final token in state.validTokens) {
      int score = 0;
      
      final nextPathPosition = token.isHome ? 0 : token.pathPosition + (state.diceValue ?? 0);
      if (nextPathPosition < currentPlayer.path.length) {
        final targetPosition = currentPlayer.path[nextPathPosition];
        
        final canCapture = gameRepository.checkCollision(targetPosition, state.players) &&
                           !gameRepository.isSafeZone(targetPosition);
        if (canCapture) {
          score += 100;
        }

        final isSafe = gameRepository.isSafeZone(targetPosition);
        final wasSafe = gameRepository.isSafeZone(token.position);
        if (isSafe && !wasSafe) {
          score += 30;
        }

        if (nextPathPosition == currentPlayer.path.length - 1) {
          score += 50;
        }
      }

      if (token.isHome && state.diceValue == 6) {
        score += 40;
      } else if (!token.isHome) {
        score += token.pathPosition;
      }

      if (score > bestScore) {
        bestScore = score;
        bestToken = token;
      }
    }

    return bestToken ?? state.validTokens.first;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => _buildExitDialog(context),
        );
        if (shouldPop ?? false) {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
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
          child: BlocListener<GameBloc, GameState>(
            listener: (context, state) {
              if (state.isGameOver) {
                SoundManager().playSound(SoundType.victory);
                if (_isAutoplay) {
                  setState(() {
                    _isAutoplay = false;
                  });
                }
              }
              if (_isAutoplay) {
                _triggerAutoplayAction(state);
              }
            },
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
                              playerName: state.currentPlayerIndex < state.players.length
                                  ? state.players[state.currentPlayerIndex].name
                                  : 'Player ${state.currentPlayerIndex + 1}',
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
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () async {
            final shouldPop = await showDialog<bool>(
              context: context,
              builder: (context) => _buildExitDialog(context),
            );
            if (shouldPop == true) {
              if (context.mounted) {
                Navigator.pop(context);
              }
            }
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isAutoplay = !_isAutoplay;
                });
                if (_isAutoplay) {
                  _triggerAutoplayAction(context.read<GameBloc>().state);
                }
              },
              icon: Icon(
                _isAutoplay ? Icons.smart_toy : Icons.smart_toy_outlined,
                color: _isAutoplay ? LudoColors.mintGreen : LudoColors.textLight,
              ),
              tooltip: 'Autoplay Mode',
            ).animate(target: _isAutoplay ? 1.0 : 0.0)
             .shimmer(duration: 1000.ms, color: LudoColors.mintGreen.withValues(alpha: 0.3)),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              icon: const Icon(Icons.settings, color: LudoColors.textLight),
            ),
          ],
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
          canRoll
              ? 'TAP TO ROLL'
              : (state.isMoving
                  ? 'MOVING TOKEN...'
                  : 'SELECT TOKEN TO MOVE'),
          style: LudoTextStyles.labelSmall.copyWith(
            color: (canRoll || (!state.canRollDice && !state.isMoving))
                ? LudoColors.mintGreen
                : LudoColors.textMedium,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ).animate(target: (canRoll || (!state.canRollDice && !state.isMoving)) ? 1.0 : 0.0)
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
                    onPressed: () => Navigator.pop(context, false),
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
                      Navigator.pop(context, true);
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

    // Build ranked player list from state.finishOrder
    final List<_PlayerRanking> rankings = [];
    for (var i = 0; i < state.finishOrder.length; i++) {
      final playerId = state.finishOrder[i];
      final p = state.players.firstWhere((player) => player.id == playerId, orElse: () => state.players[0]);
      rankings.add(_PlayerRanking(
        rank: i + 1,
        name: p.name,
        color: p.color,
      ));
    }
    final unfinished = state.players.where((p) => !state.finishOrder.contains(p.id)).toList();
    for (final p in unfinished) {
      rankings.add(_PlayerRanking(
        rank: rankings.length + 1,
        name: p.name,
        color: p.color,
      ));
    }

    final winnerColor = rankings.isNotEmpty ? rankings.first.color : LudoColors.mintGreen;
    final winnerName = rankings.isNotEmpty ? rankings.first.name : 'Winner';

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(LudoDimensions.spacing24),
            child: GlassMorphism(
              opacity: 0.1,
              blur: 20,
              borderRadius: BorderRadius.circular(LudoDimensions.radius24),
              padding: const EdgeInsets.all(LudoDimensions.spacing24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cup icon with glowing animations
                  Container(
                    width: 80,
                    height: 80,
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
                    child: const Icon(
                      Icons.emoji_events,
                      color: LudoColors.gold,
                      size: 40,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 800.ms)
                      .shimmer(duration: 1500.ms, color: Colors.white),

                  const SizedBox(height: 16),

                  Text(
                    'VICTORY!',
                    style: LudoTextStyles.displayMedium.copyWith(
                      color: winnerColor,
                      letterSpacing: 2.0,
                      fontSize: 28,
                    ),
                  ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.bounceOut),

                  const SizedBox(height: 8),

                  Text(
                    '$winnerName takes the crown!',
                    textAlign: TextAlign.center,
                    style: LudoTextStyles.headlineSmall.copyWith(
                      color: LudoColors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Leaderboard
                  Text(
                    'FINAL STANDINGS',
                    style: LudoTextStyles.labelSmall.copyWith(
                      color: LudoColors.textMedium,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rankings.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final rank = rankings[index];
                        final isWinner = rank.rank == 1;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isWinner
                                ? rank.color.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isWinner
                                  ? rank.color.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Rank Medal / Number
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isWinner
                                      ? rank.color.withValues(alpha: 0.25)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${rank.rank}',
                                    style: TextStyle(
                                      color: isWinner ? rank.color : LudoColors.textMedium,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Player Name
                              Expanded(
                                child: Text(
                                  rank.name,
                                  style: LudoTextStyles.bodyLarge.copyWith(
                                    fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                                    color: isWinner ? Colors.white : LudoColors.textLight,
                                  ),
                                ),
                              ),
                              // Status icon/trophy
                              if (isWinner)
                                const Icon(Icons.emoji_events, color: LudoColors.gold, size: 20)
                              else if (rank.rank <= state.finishOrder.length)
                                const Icon(Icons.check_circle_outline, color: LudoColors.mintGreen, size: 20)
                              else
                                const Icon(Icons.hourglass_empty, color: LudoColors.textMedium, size: 18),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats row
                  Container(
                    padding: const EdgeInsets.all(12),
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

                  const SizedBox(height: 24),

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
      ),
    );
  }
}

class _PlayerRanking {
  final int rank;
  final String name;
  final Color color;

  const _PlayerRanking({
    required this.rank,
    required this.name,
    required this.color,
  });
}
