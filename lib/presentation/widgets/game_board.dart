import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ludo_game/domain/models/player.dart';
import 'package:ludo_game/presentation/bloc/game_bloc.dart';
import 'package:ludo_game/presentation/painters/board_painter.dart';

class GameBoard extends StatefulWidget {
  final List<Player> players;
  final int currentPlayerIndex;
  final List<Token> validTokens;
  final CaptureEffect? captureEffect;

  const GameBoard({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
    required this.validTokens,
    required this.captureEffect,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  late final AnimationController _captureController;
  late final AnimationController _pulseController;
  late final Animation<double> _captureProgress;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _captureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _captureProgress = CurvedAnimation(
      parent: _captureController,
      curve: Curves.easeOutCubic,
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(covariant GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newEffect = widget.captureEffect;
    if (newEffect != null && newEffect.id != oldWidget.captureEffect?.id) {
      _captureController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _captureController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackSide = MediaQuery.sizeOf(context).shortestSide;
        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : fallbackSide;
        final maxHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : maxWidth;
        final side = maxWidth < maxHeight ? maxWidth : maxHeight;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: side,
              maxHeight: side,
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _handleTap(
                  context,
                  details.localPosition,
                  side,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _captureProgress,
                      _pulseAnimation,
                    ]),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: BoardPainter(
                          players: widget.players,
                          currentPlayerIndex: widget.currentPlayerIndex,
                          validTokens: widget.validTokens,
                          captureEffect: widget.captureEffect,
                          captureProgress: _captureProgress.value,
                          validPulse: _pulseAnimation.value,
                        ),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(
    BuildContext context,
    Offset localPosition,
    double boardSize,
  ) {
    if (widget.validTokens.isEmpty || boardSize <= 0) return;

    final cellSize = boardSize / 15;
    final x = (localPosition.dx / cellSize).floor().clamp(0, 14);
    final y = (localPosition.dy / cellSize).floor().clamp(0, 14);

    for (final token in widget.validTokens) {
      final position = token.position;
      if (position != null && position.x == x && position.y == y) {
        context.read<GameBloc>().add(SelectToken(token));
        break;
      }
    }
  }
}
