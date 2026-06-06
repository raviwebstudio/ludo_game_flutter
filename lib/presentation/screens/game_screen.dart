import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ludo_game/presentation/bloc/game_bloc.dart';
import 'package:ludo_game/presentation/widgets/game_board.dart';
import 'package:ludo_game/presentation/widgets/dice_widget.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  static const double _maxContentWidth = 820;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          " ",
          style: GoogleFonts.poppins(),
        ),
      ),
      body: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          if (state.isGameOver) {
            return _buildGameOverScreen(context, state);
          }

          if (state.players.isEmpty) {
            return const SafeArea(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mediaSize = MediaQuery.sizeOf(context);
                final horizontalPadding = _clampDouble(
                  constraints.maxWidth * 0.04,
                  12,
                  32,
                );
                final verticalPadding = _clampDouble(
                  constraints.maxHeight * 0.02,
                  8,
                  20,
                );
                final diceSize = _clampDouble(
                  mediaSize.shortestSide * 0.12,
                  44,
                  64,
                );
                final rowHeight = diceSize + 12;
                final gap = _clampDouble(
                  constraints.maxHeight * 0.015,
                  8,
                  16,
                );
                final contentWidth = math.max(
                  0.0,
                  math.min(
                    _maxContentWidth,
                    constraints.maxWidth - horizontalPadding * 2,
                  ),
                );
                final boardHeight = math.max(
                  0.0,
                  constraints.maxHeight -
                      verticalPadding * 2 -
                      rowHeight * 2 -
                      gap * 2,
                );
                final boardSide = math.min(contentWidth, boardHeight);

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxContentWidth,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTurnBanner(context, state, diceSize),
                          SizedBox(height: gap),
                          _buildPlayerRow(
                            context,
                            state,
                            leftPlayerIndex: 0,
                            rightPlayerIndex: 1,
                            rowHeight: rowHeight,
                            diceSize: diceSize,
                          ),
                          SizedBox(height: gap),
                          SizedBox.square(
                            dimension: boardSide,
                            child: GameBoard(
                              players: state.players,
                              currentPlayerIndex: state.currentPlayerIndex,
                              validTokens: state.validTokens,
                              captureEffect: state.captureEffect,
                            ),
                          ),
                          SizedBox(height: gap),
                          _buildPlayerRow(
                            context,
                            state,
                            leftPlayerIndex: 3,
                            rightPlayerIndex: 2,
                            rowHeight: rowHeight,
                            diceSize: diceSize,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTurnBanner(
      BuildContext context, GameState state, double diceSize) {
    final activePlayerIndex = state.currentPlayerIndex;
    final isGameOver = state.isGameOver;
    final playerName = state.players.isNotEmpty
      ? (state.players[activePlayerIndex].name.isNotEmpty
        ? state.players[activePlayerIndex].name
        : 'Player ${activePlayerIndex + 1}')
      : 'Player ${activePlayerIndex + 1}';
    final title = isGameOver ? '$playerName Wins!' : "$playerName's Turn";
    final activeColor = state.players.isNotEmpty
        ? state.players[activePlayerIndex].color
        : Theme.of(context).colorScheme.primary;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(title),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activeColor.withValues(alpha: 0.38),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: diceSize * 0.18,
              height: diceSize * 0.18,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: 0.4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: _clampDouble(diceSize * 0.25, 14, 18),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRow(
    BuildContext context,
    GameState state, {
    required int leftPlayerIndex,
    required int rightPlayerIndex,
    required double rowHeight,
    required double diceSize,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final children = [
          _buildPlayerSeat(
            context,
            state,
            playerIndex: leftPlayerIndex,
            diceFirst: true,
            diceSize: diceSize,
          ),
          _buildPlayerSeat(
            context,
            state,
            playerIndex: rightPlayerIndex,
            diceFirst: false,
            diceSize: diceSize,
          ),
        ];

        if (isCompact) {
          return Column(
            children: [
              children[0],
              const SizedBox(height: 8),
              children[1],
            ],
          );
        }

        return SizedBox(
          height: rowHeight,
          child: Row(
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 12),
              Expanded(child: children[1]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerSeat(
    BuildContext context,
    GameState state, {
    required int playerIndex,
    required bool diceFirst,
    required double diceSize,
  }) {
    final isPresent = playerIndex < state.players.length;
    final isCurrentPlayer = state.currentPlayerIndex == playerIndex;
    final canRoll =
        isPresent && isCurrentPlayer && state.canRollDice && !state.isMoving;
    final activeColor = isPresent
        ? state.players[playerIndex].color
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    final labelStyle = GoogleFonts.poppins(
      fontSize: _clampDouble(diceSize * 0.26, 12, 16),
      fontWeight: isCurrentPlayer ? FontWeight.w700 : FontWeight.w500,
      color: isPresent ? Colors.black87 : Colors.black38,
    );
    final dice = DiceWidget(
      value: isCurrentPlayer ? state.diceValue : null,
      enabled: canRoll,
      isActivePlayer: isCurrentPlayer,
      activeColor: activeColor,
      size: diceSize,
      onRoll: () {
        final completer = Completer<int?>();
        context.read<GameBloc>().add(RollDice(resultCompleter: completer));
        return completer.future;
      },
    );
    final label = Flexible(
      child: Text(
        state.players.length > playerIndex && state.players[playerIndex].name.isNotEmpty
            ? state.players[playerIndex].name
            : 'Player ${playerIndex + 1}',
        overflow: TextOverflow.ellipsis,
        textAlign: diceFirst ? TextAlign.left : TextAlign.right,
        maxLines: 1,
        style: labelStyle,
      ),
    );

    return Opacity(
      opacity: isPresent ? 1 : 0.35,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment:
            diceFirst ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: diceFirst
            ? [
                dice,
                const SizedBox(width: 8),
                label,
              ]
            : [
                label,
                const SizedBox(width: 8),
                dice,
              ],
      ),
    );
  }

  Widget _buildGameOverScreen(BuildContext context, GameState state) {
    final duration =
        DateTime.now().difference(state.startTime ?? DateTime.now());

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleSize = _clampDouble(constraints.maxWidth * 0.12, 32, 48);
          final winnerSize = _clampDouble(constraints.maxWidth * 0.06, 18, 24);
          final bodySize = _clampDouble(constraints.maxWidth * 0.05, 16, 20);

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF11998E),
                  Color(0xFF38EF7D),
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Card(
                      elevation: 8.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.all(24),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Game Over!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.rubikVinyl(
                                fontSize: titleSize,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Winner: Player ${state.currentPlayerIndex + 1}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: winnerSize,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Time: ${duration.inMinutes}m ${duration.inSeconds % 60}s',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: bodySize,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 40),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.replay),
                              label: Text(
                                'Play Again',
                                style: GoogleFonts.poppins(
                                  fontSize: bodySize,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _clampDouble(double value, double minimum, double maximum) {
    return value.clamp(minimum, maximum).toDouble();
  }
}
