import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/player.dart';
import '../../../presentation/bloc/game_bloc.dart';
import 'modern_board_painter.dart';

/// The interactive game board widget.
///
/// This is the drop‑in replacement for the original [GameBoard] widget.
/// It uses [ModernBoardPainter] for the dark premium look while preserving
/// the exact same tap‑handling and animation logic.
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
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : fallbackSide;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : maxW;
        final side = maxW < maxH ? maxW : maxH;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: side, maxHeight: side),
            child: AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    _handleTap(context, details.localPosition, side),
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _captureProgress,
                    _pulseAnimation,
                  ]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: ModernBoardPainter(
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
        );
      },
    );
  }

  void _handleTap(BuildContext context, Offset localPos, double boardSize) {
    if (widget.validTokens.isEmpty || boardSize <= 0) return;

    final cellSize = boardSize / 15;
    final x = (localPos.dx / cellSize).floor().clamp(0, 14);
    final y = (localPos.dy / cellSize).floor().clamp(0, 14);

    for (final token in widget.validTokens) {
      final pos = token.position;
      if (pos != null && pos.x == x && pos.y == y) {
        context.read<GameBloc>().add(SelectToken(token));
        break;
      }
    }
  }
}
