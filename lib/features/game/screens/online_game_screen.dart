import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ludo_game/injection.dart';
import 'package:ludo_game/core/constants/colors.dart';
import 'package:ludo_game/core/constants/dimensions.dart';
import 'package:ludo_game/core/constants/text_styles.dart';
import 'package:ludo_game/core/services/sound_manager.dart';
import 'package:ludo_game/shared/widgets/glass_morphism.dart';
import 'package:ludo_game/shared/widgets/gradient_button.dart';
import '../../../presentation/bloc/online_game_bloc.dart';
import '../widgets/board_container.dart';
import '../widgets/dice_widget.dart';
import '../widgets/game_board.dart';
import '../widgets/player_indicators.dart';
import '../widgets/turn_indicator.dart';

class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({super.key});

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  late final OnlineGameBloc _onlineGameBloc;
  static const double _maxContentWidth = 420;

  @override
  void initState() {
    super.initState();
    _onlineGameBloc = getIt<OnlineGameBloc>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lobbyId = ModalRoute.of(context)!.settings.arguments as String;
    _onlineGameBloc.add(InitOnlineGame(lobbyId));
  }

  @override
  void dispose() {
    _onlineGameBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _onlineGameBloc,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => _buildExitDialog(context),
          );
          if (shouldPop ?? false) {
            _onlineGameBloc.add(LeaveGameOnline());
            if (context.mounted) {
              Navigator.of(context).popUntil(ModalRoute.withName('/home'));
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
            child: BlocListener<OnlineGameBloc, OnlineGameState>(
              listenWhen: (previous, current) =>
                  previous.gameState != null &&
                  current.gameState != null &&
                  !previous.gameState!.isGameOver &&
                  current.gameState!.isGameOver,
              listener: (context, state) {
                SoundManager().playSound(SoundType.victory);
              },
              child: BlocBuilder<OnlineGameBloc, OnlineGameState>(
                builder: (context, state) {
                  if (state.isLobbyLoading || state.gameState == null) {
                    return const SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: LudoColors.brightBlue,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Syncing Arena State...',
                              style: TextStyle(color: LudoColors.textLight, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final gState = state.gameState!;

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
                                players: gState.players,
                                currentPlayerIndex: gState.currentPlayerIndex,
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
                                        players: gState.players,
                                        currentPlayerIndex: gState.currentPlayerIndex,
                                        validTokens: state.isMyTurn ? gState.validTokens : const [],
                                        captureEffect: gState.captureEffect,
                                        onTokenTap: (token) {
                                          if (state.isMyTurn) {
                                            context.read<OnlineGameBloc>().add(SelectTokenOnline(token));
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),

                              const SizedBox(height: LudoDimensions.spacing16),

                              // Bottom Players Indicators (3 and 2)
                              PlayerIndicators(
                                players: gState.players,
                                currentPlayerIndex: gState.currentPlayerIndex,
                                leftIndex: 3,
                                rightIndex: 2,
                              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                              const Spacer(),

                              // Turn Indicator Banner
                              TurnIndicator(
                                playerIndex: gState.currentPlayerIndex,
                                playerName: gState.currentPlayerIndex < gState.players.length
                                    ? (state.isMyTurn ? 'YOUR TURN' : gState.players[gState.currentPlayerIndex].name)
                                    : 'Player ${gState.currentPlayerIndex + 1}',
                                playerColor: gState.currentPlayerIndex < gState.players.length
                                    ? gState.players[gState.currentPlayerIndex].color
                                    : LudoColors.purple,
                                isGameOver: gState.isGameOver,
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
                      if (gState.isGameOver)
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
              _onlineGameBloc.add(LeaveGameOnline());
              if (context.mounted) {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              }
            }
          },
          icon: const Icon(Icons.arrow_back_ios, color: LudoColors.textLight),
        ),
        Text(
          'ARENA MULTIPLAYER',
          style: LudoTextStyles.displayMedium.copyWith(
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 48), // Spacer to balance back icon
      ],
    );
  }

  Widget _buildCentralDice(BuildContext context, OnlineGameState state) {
    final gState = state.gameState!;
    final activePlayerIndex = gState.currentPlayerIndex;
    final isPresent = activePlayerIndex < gState.players.length;
    final canRoll = isPresent && state.isMyTurn && gState.canRollDice && !gState.isMoving;
    final activeColor = isPresent ? gState.players[activePlayerIndex].color : LudoColors.purple;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DiceWidget(
          value: gState.diceValue,
          enabled: canRoll,
          isActivePlayer: canRoll,
          activeColor: activeColor,
          size: 88,
          onRoll: () {
            final completer = Completer<int?>();
            context.read<OnlineGameBloc>().add(RollDiceOnline(resultCompleter: completer));
            return completer.future;
          },
        ),
        const SizedBox(height: 8),
        Text(
          canRoll
              ? 'YOUR TURN - TAP TO ROLL'
              : (state.isMyTurn
                  ? 'SELECT TOKEN TO MOVE'
                  : "WAITING FOR ${gState.players[activePlayerIndex].name.toUpperCase()}"),
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
              'Leave Arena?',
              style: LudoTextStyles.headlineSmall.copyWith(color: LudoColors.textLight),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to forfeit this online game? You will be removed from the lobby.',
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
                    label: 'Forfeit',
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

  Widget _buildGameOverOverlay(BuildContext context, OnlineGameState state) {
    final gState = state.gameState!;
    final duration = DateTime.now().difference(gState.startTime ?? DateTime.now());

    final List<_PlayerRanking> rankings = [];
    for (var i = 0; i < gState.finishOrder.length; i++) {
      final playerId = gState.finishOrder[i];
      final p = gState.players.firstWhere((player) => player.id == playerId, orElse: () => gState.players[0]);
      rankings.add(_PlayerRanking(
        rank: i + 1,
        name: p.name,
        color: p.color,
      ));
    }
    final unfinished = gState.players.where((p) => !gState.finishOrder.contains(p.id)).toList();
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
                              Expanded(
                                child: Text(
                                  rank.name,
                                  style: LudoTextStyles.bodyLarge.copyWith(
                                    fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                                    color: isWinner ? Colors.white : LudoColors.textLight,
                                  ),
                                ),
                              ),
                              if (isWinner)
                                const Icon(Icons.emoji_events, color: LudoColors.gold, size: 20)
                              else if (rank.rank <= gState.finishOrder.length)
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
                    label: 'EXIT ARENA',
                    onPressed: () {
                      _onlineGameBloc.add(LeaveGameOnline());
                      Navigator.popUntil(context, ModalRoute.withName('/home'));
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
