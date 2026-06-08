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

  final void Function(Token)? onTokenTap;

  const GameBoard({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
    required this.validTokens,
    required this.captureEffect,
    this.onTokenTap,
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

    final tokensOnCell = widget.validTokens.where((t) => t.position?.x == x && t.position?.y == y).toList();

    if (tokensOnCell.isNotEmpty) {
      if (tokensOnCell.length == 1) {
        if (widget.onTokenTap != null) {
          widget.onTokenTap!(tokensOnCell.first);
        } else {
          context.read<GameBloc>().add(SelectToken(tokensOnCell.first));
        }
      } else {
        // Find closest by offset center
        Token? closestToken;
        double minDistance = double.infinity;
        for (final token in tokensOnCell) {
          final pos = token.position!;
          var center = Offset(
            (pos.x + 0.5) * cellSize,
            (pos.y + 0.5) * cellSize,
          );

          // Check if there are other players' tokens on this cell
          // (If so, we draw this token with an offset)
          final allTokensAtPos = widget.players.expand((p) => p.tokens).where((t) => t.position == pos).toList();
          final uniquePlayerIds = allTokensAtPos.map((t) => widget.players.firstWhere((p) => p.tokens.contains(t)).id).toSet();

          if (uniquePlayerIds.length >= 2) {
            final idx = allTokensAtPos.indexOf(token);
            final off = idx * cellSize * 0.1;
            center = center + Offset(-off, -off);
          }

          final distance = (localPos - center).distance;
          if (distance < minDistance) {
            minDistance = distance;
            closestToken = token;
          }
        }
        if (closestToken != null) {
          if (widget.onTokenTap != null) {
            widget.onTokenTap!(closestToken);
          } else {
            context.read<GameBloc>().add(SelectToken(closestToken));
          }
        }
      }
    }
  }
}
