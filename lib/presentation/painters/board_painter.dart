import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ludo_game/domain/models/player.dart';
import 'package:ludo_game/domain/models/board_position.dart';
import 'package:ludo_game/domain/services/safe_zones.dart';
import 'package:ludo_game/presentation/bloc/game_bloc.dart';

class BoardPainter extends CustomPainter {
  final List<Player> players;
  final int currentPlayerIndex;
  final List<Token> validTokens;
  final CaptureEffect? captureEffect;
  final double captureProgress;
  final double validPulse;

  BoardPainter({
    required this.players,
    required this.currentPlayerIndex,
    required this.validTokens,
    this.captureEffect,
    this.captureProgress = 1,
    this.validPulse = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boardSize = size.width;
    final cellSize = boardSize / 15;

    _drawBackground(canvas, size);
    _drawPlayerHomes(canvas, size, cellSize);
    _drawCenterPaths(canvas, size, cellSize);
    _drawSafeSpots(canvas, size, cellSize);
    _drawBlockades(canvas, size, cellSize);
    _drawHomeStretch(canvas, size, cellSize);
    _drawTokens(canvas, size, cellSize);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, backgroundPaint);
  }

  void _drawPlayerHomes(Canvas canvas, Size size, double cellSize) {
    final homeSize = 6 * cellSize;
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.yellow];
    final homePositions = [
      Offset.zero,
      Offset(size.width - homeSize, 0),
      Offset(size.width - homeSize, size.height - homeSize),
      Offset(0, size.height - homeSize),
    ];

    for (var i = 0; i < colors.length; i++) {
      _drawHome(canvas, homePositions[i], homeSize, colors[i]);
    }
  }

  void _drawHome(Canvas canvas, Offset offset, double size, Color color) {
    final homePaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = Rect.fromLTWH(offset.dx, offset.dy, size, size);
    canvas.drawRect(rect, homePaint);
    canvas.drawRect(rect, borderPaint);

    // Draw token spots
    final spotPositions = [
      Offset(offset.dx + size * 0.25, offset.dy + size * 0.25),
      Offset(offset.dx + size * 0.75, offset.dy + size * 0.25),
      Offset(offset.dx + size * 0.25, offset.dy + size * 0.75),
      Offset(offset.dx + size * 0.75, offset.dy + size * 0.75),
    ];

    for (final spotOffset in spotPositions) {
      canvas.drawCircle(
        spotOffset,
        size * 0.15,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        spotOffset,
        size * 0.15,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  void _drawCenterPaths(Canvas canvas, Size size, double cellSize) {
    final pathPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    // Vertical path
    canvas.drawRect(
      Rect.fromLTWH(6 * cellSize, 0, 3 * cellSize, size.height),
      pathPaint,
    );

    // Horizontal path
    canvas.drawRect(
      Rect.fromLTWH(0, 6 * cellSize, size.width, 3 * cellSize),
      pathPaint,
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var i = 0; i <= 15; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        gridPaint,
      );
    }
  }

  void _drawSafeSpots(Canvas canvas, Size size, double cellSize) {
    final colors = [Colors.red, Colors.green, Colors.yellow, Colors.blue];
    final startSafeSpotColors = <BoardPosition, Color>{
      for (final entry in SafeZoneService.playerStartSafeZones.entries)
        if (entry.key < colors.length)
          entry.value: colors[entry.key].withValues(alpha: 0.9),
    };

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final spot in SafeZoneService.safeZones) {
      final center =
          Offset((spot.x + 0.5) * cellSize, (spot.y + 0.5) * cellSize);
      final spotColor = startSafeSpotColors[spot] ?? Colors.grey[200]!;

      // Use specific player's color or the neutral color
      final safePaint = Paint()
        ..color = spotColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, cellSize * 0.4, safePaint);
      canvas.drawCircle(center, cellSize * 0.4, borderPaint);

      // Draw star pattern
      _drawStar(canvas, center, cellSize * 0.3, borderPaint);
    }
  }

  void _drawBlockades(Canvas canvas, Size size, double cellSize) {
    final Map<BoardPosition, int> tokenCounts = {};

    for (final player in players) {
      for (final token in player.tokens) {
        if (token.position != null && !token.isHome && !token.isFinished) {
          tokenCounts[token.position!] =
              (tokenCounts[token.position!] ?? 0) + 1;
        }
      }
    }

    final fillPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    tokenCounts.forEach((position, count) {
      if (count >= 2 && !SafeZoneService.isSafeZone(position)) {
        final center = Offset(
          (position.x + 0.5) * cellSize,
          (position.y + 0.5) * cellSize,
        );
        canvas.drawCircle(center, cellSize * 0.38, fillPaint);
        canvas.drawCircle(center, cellSize * 0.38, borderPaint);
      }
    });
  }

  void _drawStar(
      Canvas canvas, Offset center, double outerRadius, Paint paint) {
    // Number of points in the star
    const int numPoints = 5;
    // Ratio of the inner radius compared to the outer
    final double innerRadius = outerRadius * 0.5;
    final path = Path();
    double angle = -pi / 2; // Start at the top of the star

    for (int i = 0; i < numPoints * 2; i++) {
      // Toggle between outer and inner points
      final double radius = i.isEven ? outerRadius : innerRadius;

      // Calculate the position for each point
      final double x = center.dx + radius * cos(angle);
      final double y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Increment the angle
      angle +=
          pi / numPoints; // 360 degrees divided by twice the number of points
    }
    path.close(); // Complete the star outline by closing the path
    canvas.drawPath(path, paint);
  }

  void _drawHomeStretch(Canvas canvas, Size size, double cellSize) {
    final colors = [Colors.red, Colors.green, Colors.yellow, Colors.blue];

    final center = Offset(7.5 * cellSize, 7.5 * cellSize);

    // Draw red triangle
    _drawTriangle(canvas, Offset(6 * cellSize, 6 * cellSize), center,
        Offset(6 * cellSize, 9 * cellSize), colors[0]);

    // Draw green triangle
    _drawTriangle(canvas, Offset(6 * cellSize, 6 * cellSize), center,
        Offset(9 * cellSize, 6 * cellSize), colors[1]);

    // Draw yellow triangle
    _drawTriangle(canvas, Offset(9 * cellSize, 6 * cellSize), center,
        Offset(9 * cellSize, 9 * cellSize), colors[2]);

    // Draw blue triangle
    _drawTriangle(canvas, Offset(6 * cellSize, 9 * cellSize), center,
        Offset(9 * cellSize, 9 * cellSize), colors[3]);

    // Red home stretch (horizontal, left)
    _drawColoredPath(
        canvas, 1 * cellSize, 7 * cellSize, 5 * cellSize, cellSize, colors[0]);
    // Gree  home stretch (vertical, top)
    _drawColoredPath(
        canvas, 7 * cellSize, 1 * cellSize, cellSize, 5 * cellSize, colors[1]);
    // Yellow home stretch (horizontal, right)
    _drawColoredPath(
        canvas, 9 * cellSize, 7 * cellSize, 5 * cellSize, cellSize, colors[2]);
    // Blue home stretch (vertical, bottom)
    _drawColoredPath(
        canvas, 7 * cellSize, 9 * cellSize, cellSize, 5 * cellSize, colors[3]);
  }

  void _drawTriangle(
      Canvas canvas, Offset start, Offset pivot, Offset end, Color color) {
    final path = Path()..moveTo(start.dx, start.dy);
    path.lineTo(pivot.dx, pivot.dy);
    path.lineTo(end.dx, end.dy);
    path.close();

    final paint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  void _drawColoredPath(Canvas canvas, double x, double y, double width,
      double height, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rect = Rect.fromLTWH(x, y, width, height);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
  }

  void _drawTokens(Canvas canvas, Size size, double cellSize) {
    final currentPlayerId =
        currentPlayerIndex >= 0 && currentPlayerIndex < players.length
            ? players[currentPlayerIndex].id
            : null;

    // Map to keep track of the number of tokens in each position
    final Map<BoardPosition, int> tokenCounts = {};

    // Increment token count for each position
    for (final player in players) {
      for (final token in player.tokens) {
        if (token.position != null) {
          tokenCounts[token.position!] =
              (tokenCounts[token.position!] ?? 0) + 1;
        }
      }
    }

    // Draw tokens with offset if the count at the position is greater than 1
    for (final player in players) {
      for (final token in player.tokens) {
        if (token.position != null) {
          final center = Offset(
            (token.position!.x + 0.5) * cellSize,
            (token.position!.y + 0.5) * cellSize,
          );

          // Check how many tokens are at this position
          final tokenCount = tokenCounts[token.position!] ?? 1;
          final baseRadius = cellSize * 0.28; // smaller tokens to keep grid visible
          if (tokenCount > 1) {
            // Add a slight offset for each token in the stack for visibility
            final index = player.tokens.indexOf(token);
            final offsetAmount = (index % tokenCount) * cellSize * 0.08;
            final adjustedCenter =
                center + Offset(-offsetAmount, -offsetAmount);

            _drawToken(
              canvas,
              adjustedCenter,
              baseRadius,
              player.color,
              validTokens.contains(token),
              currentPlayerId == player.id,
            );
          } else {
            _drawToken(
              canvas,
              center,
              baseRadius,
              player.color,
              validTokens.contains(token),
              currentPlayerId == player.id,
            );
          }
        }
      }
    }

    _drawCaptureOverlay(canvas, cellSize);
  }

  void _drawToken(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    bool isValid,
    bool isCurrentPlayer,
  ) {
    final shadowRadius = radius * 0.18;
    final effectiveRadius = radius;

    // Draw shadow
    canvas.drawCircle(
      center.translate(2, 2),
      effectiveRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );

    // Draw token background
    canvas.drawCircle(
      center,
      effectiveRadius,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Draw token border
    canvas.drawCircle(
      center,
      effectiveRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Draw highlight for valid moves
    if (isValid) {
      final radiusGlow = effectiveRadius * (1.2 + validPulse * 0.22);
      canvas.drawCircle(
        center,
        radiusGlow,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28 + validPulse * 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
      canvas.drawCircle(
        center,
        radiusGlow + shadowRadius * 0.6,
        Paint()
          ..color = color.withValues(alpha: 0.12 + validPulse * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Draw current player indicator
    if (isCurrentPlayer) {
      canvas.drawCircle(
        center,
        effectiveRadius * 0.58,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawCaptureOverlay(Canvas canvas, double cellSize) {
    if (captureEffect == null) return;

    final effect = captureEffect!;
    final startCenter = Offset(
      (effect.position.x + 0.5) * cellSize,
      (effect.position.y + 0.5) * cellSize,
    );
    final homeCenter = Offset(
      (effect.homePosition.x + 0.5) * cellSize,
      (effect.homePosition.y + 0.5) * cellSize,
    );
    final tokenColor = players
        .firstWhere(
          (player) => player.id == effect.playerId,
          orElse: () => players.isNotEmpty
              ? players.first
              : Player(
                  id: 0, color: Colors.red, tokens: const [], path: const []),
        )
        .color
        .withValues(alpha: 1.0);
    final currentCenter =
        Offset.lerp(startCenter, homeCenter, captureProgress) ?? homeCenter;
    final returnRadius =
        cellSize * (0.32 - 0.10 * captureProgress).clamp(0.18, 0.32);
    final burstAlpha = (1 - captureProgress).clamp(0.0, 1.0);

    // Trail from capture to home
    final path = Path()
      ..moveTo(startCenter.dx, startCenter.dy)
      ..quadraticBezierTo(
        (startCenter.dx + homeCenter.dx) / 2,
        (startCenter.dy + homeCenter.dy) / 2 - cellSize * 0.6,
        homeCenter.dx,
        homeCenter.dy,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = tokenColor.withValues(alpha: 0.28 * burstAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - captureProgress),
    );

    // Capture burst
    final burstPaint = Paint()
      ..color = tokenColor.withValues(alpha: burstAlpha * 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: burstAlpha * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(
      startCenter,
      cellSize * (0.35 + 0.4 * burstAlpha),
      ringPaint,
    );

    for (var i = 0; i < 8; i++) {
      final angle = (pi * 2 / 8) * i;
      final direction = Offset(cos(angle), sin(angle));
      final start =
          startCenter + direction * cellSize * (0.85 + burstAlpha * 0.35);
      final end =
          startCenter + direction * cellSize * (1.5 + burstAlpha * 0.75);
      canvas.drawLine(start, end, burstPaint);
    }

    // Moving captured token overlay
    canvas.drawCircle(
      currentCenter,
      returnRadius,
      Paint()
        ..color = tokenColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      currentCenter,
      returnRadius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return oldDelegate.players != players ||
        oldDelegate.currentPlayerIndex != currentPlayerIndex ||
        oldDelegate.validTokens != validTokens ||
        oldDelegate.captureEffect != captureEffect ||
        oldDelegate.captureProgress != captureProgress ||
        oldDelegate.validPulse != validPulse;
  }
}
