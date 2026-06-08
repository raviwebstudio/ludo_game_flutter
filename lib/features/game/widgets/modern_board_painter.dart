import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/player_prefs.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/board_position.dart';
import '../../../domain/services/safe_zones.dart';
import '../../../presentation/bloc/game_bloc.dart';

/// A board painter matching the Ludo Elite reference designs with support for custom themes.
///
/// Theme options: Neon Dark, Classic Board, Royal Gold (adapted for light mode visibility).
class ModernBoardPainter extends CustomPainter {
  final List<Player> players;
  final int currentPlayerIndex;
  final List<Token> validTokens;
  final CaptureEffect? captureEffect;
  final double captureProgress;
  final double validPulse;

  ModernBoardPainter({
    required this.players,
    required this.currentPlayerIndex,
    required this.validTokens,
    this.captureEffect,
    this.captureProgress = 1,
    this.validPulse = 0,
  });

  // ── Player colours ──────────────────────────────────────────────────────
  static const List<Color> _playerColors = [
    LudoColors.redToken,
    LudoColors.greenToken,
    LudoColors.yellowToken,
    LudoColors.blueToken,
  ];

  static Color _playerColor(int index) =>
      index < _playerColors.length ? _playerColors[index] : LudoColors.textMedium;

  // ── Paint ───────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 15;

    // Load active board theme
    final theme = PlayerPrefs.boardTheme;
    final isClassic = theme == 'Classic Board';
    final isGold = theme == 'Royal Gold';

    // Theme values (adapted for light backgrounds)
    final boardBg = isClassic
        ? const Color(0xFFF2F4F8)
        : (isGold ? const Color(0xFFFFFDF0) : const Color(0xFFEDE8DC)); // Light warm beige for Neon Dark
    final cellBorderColor = const Color(0xFFAAA7AD);
    final centerPathBg = Colors.white;
    final homeStretchAlpha = 0.18;
    final homeBgAlpha = isClassic ? 0.35 : (isGold ? 0.22 : 0.18);

    _drawBackground(canvas, size, cellSize, boardBg);
    _drawCenterPaths(canvas, size, cellSize, centerPathBg);
    _drawPlayerHomes(canvas, size, cellSize, homeBgAlpha);
    _drawHomeStretchFills(canvas, size, cellSize, homeStretchAlpha);
    _drawAllGridLines(canvas, size, cellSize, cellBorderColor);
    _drawSafeSpots(canvas, size, cellSize);
    _drawTokens(canvas, size, cellSize);
  }

  // ── Background ──────────────────────────────────────────────────────────

  void _drawBackground(Canvas canvas, Size size, double cellSize, Color boardBg) {
    // Board background
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = boardBg,
    );
  }

  // ── Player Homes ────────────────────────────────────────────────────────

  void _drawPlayerHomes(Canvas canvas, Size size, double cellSize, double homeBgAlpha) {
    final homeSize = 6 * cellSize;
    final positions = [
      Offset.zero,
      Offset(size.width - homeSize, 0),
      Offset(size.width - homeSize, size.height - homeSize),
      Offset(0, size.height - homeSize),
    ];

    for (var i = 0; i < 4; i++) {
      _drawModernHome(canvas, positions[i], homeSize, _playerColor(i), i, homeBgAlpha);
    }
  }

  void _drawModernHome(
    Canvas canvas,
    Offset offset,
    double size,
    Color color,
    int playerIndex,
    double homeBgAlpha,
  ) {
    final rect = Rect.fromLTWH(offset.dx, offset.dy, size, size);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Background
    canvas.drawRRect(
      rr,
      Paint()..color = color.withValues(alpha: homeBgAlpha),
    );

    // Yard Border - Medium gray
    canvas.drawRRect(
      rr,
      Paint()
        ..color = const Color(0xFFAAA7AD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Inner box for token slots
    final innerMargin = size * 0.18;
    final innerRect = Rect.fromLTWH(
      offset.dx + innerMargin,
      offset.dy + innerMargin,
      size - innerMargin * 2,
      size - innerMargin * 2,
    );
    final innerRR = RRect.fromRectAndRadius(innerRect, const Radius.circular(10));
    canvas.drawRRect(
      innerRR,
      Paint()..color = Colors.black.withValues(alpha: 0.04), // Dark tint instead of white
    );

    // 4 token slot circles
    final slotSize = (size - innerMargin * 2) / 2;
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 2; col++) {
        final cx = offset.dx + innerMargin + slotSize * (col + 0.5);
        final cy = offset.dy + innerMargin + slotSize * (row + 0.5);
        // Light rounded slot
        final slotRR = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: slotSize * 0.8,
            height: slotSize * 0.35,
          ),
          Radius.circular(slotSize * 0.18),
        );
        canvas.drawRRect(
          slotRR,
          Paint()..color = const Color(0xFFF0F0F5), // Light background slot
        );

        // Slot border
        canvas.drawRRect(
          slotRR,
          Paint()
            ..color = color.withValues(alpha: 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      }
    }
  }

  // ── Center Paths ────────────────────────────────────────────────────────

  void _drawCenterPaths(Canvas canvas, Size size, double cellSize, Color centerPathBg) {
    final pathBg = Paint()..color = centerPathBg;

    // Vertical path background
    canvas.drawRect(
      Rect.fromLTWH(6 * cellSize, 0, 3 * cellSize, size.height),
      pathBg,
    );
    // Horizontal path background
    canvas.drawRect(
      Rect.fromLTWH(0, 6 * cellSize, size.width, 3 * cellSize),
      pathBg,
    );
  }

  // ── Home Stretch & Center ───────────────────────────────────────────────

  void _drawHomeStretchFills(Canvas canvas, Size size, double cellSize, double stretchAlpha) {
    final center = Offset(7.5 * cellSize, 7.5 * cellSize);

    // Center triangles
    _drawTriangleFill(
      canvas,
      Offset(6 * cellSize, 6 * cellSize),
      center,
      Offset(6 * cellSize, 9 * cellSize),
      _playerColor(0),
    );
    _drawTriangleFill(
      canvas,
      Offset(6 * cellSize, 6 * cellSize),
      center,
      Offset(9 * cellSize, 6 * cellSize),
      _playerColor(1),
    );
    _drawTriangleFill(
      canvas,
      Offset(9 * cellSize, 6 * cellSize),
      center,
      Offset(9 * cellSize, 9 * cellSize),
      _playerColor(2),
    );
    _drawTriangleFill(
      canvas,
      Offset(6 * cellSize, 9 * cellSize),
      center,
      Offset(9 * cellSize, 9 * cellSize),
      _playerColor(3),
    );

    // Home stretch coloured paths
    _drawColoredStretchFill(
        canvas, 1 * cellSize, 7 * cellSize, 5 * cellSize, cellSize, _playerColor(0), stretchAlpha);
    _drawColoredStretchFill(
        canvas, 7 * cellSize, 1 * cellSize, cellSize, 5 * cellSize, _playerColor(1), stretchAlpha);
    _drawColoredStretchFill(
        canvas, 9 * cellSize, 7 * cellSize, 5 * cellSize, cellSize, _playerColor(2), stretchAlpha);
    _drawColoredStretchFill(
        canvas, 7 * cellSize, 9 * cellSize, cellSize, 5 * cellSize, _playerColor(3), stretchAlpha);
  }

  void _drawTriangleFill(
    Canvas canvas,
    Offset a,
    Offset b,
    Offset c,
    Color color,
  ) {
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawColoredStretchFill(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    Color color,
    double stretchAlpha,
  ) {
    final rect = Rect.fromLTWH(x, y, w, h);
    canvas.drawRect(
      rect,
      Paint()..color = color.withValues(alpha: stretchAlpha),
    );
  }

  // ── Grid Lines ──────────────────────────────────────────────────────────

  void _drawAllGridLines(Canvas canvas, Size size, double cellSize, Color cellBorderColor) {
    final gridPaint = Paint()
      ..color = cellBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw borders for all cells in vertical path (cols 6..8)
    for (var x = 6; x < 9; x++) {
      for (var y = 0; y < 15; y++) {
        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          gridPaint,
        );
      }
    }

    // Draw borders for all cells in horizontal path (rows 6..8)
    for (var y = 6; y < 9; y++) {
      for (var x = 0; x < 15; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          gridPaint,
        );
      }
    }

    // Draw the center triangle outlines
    final centerPaint = Paint()
      ..color = cellBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(6 * cellSize, 6 * cellSize)
      ..lineTo(9 * cellSize, 9 * cellSize)
      ..moveTo(6 * cellSize, 9 * cellSize)
      ..lineTo(9 * cellSize, 6 * cellSize);
    canvas.drawPath(path, centerPaint);

    // Border around the center 3x3 square
    canvas.drawRect(
      Rect.fromLTWH(6 * cellSize, 6 * cellSize, 3 * cellSize, 3 * cellSize),
      centerPaint,
    );
  }

  // ── Safe Spots ──────────────────────────────────────────────────────────

  void _drawSafeSpots(Canvas canvas, Size size, double cellSize) {
    final startColors = <BoardPosition, Color>{
      for (final entry in SafeZoneService.playerStartSafeZones.entries)
        if (entry.key < _playerColors.length)
          entry.value: _playerColor(entry.key),
    };

    for (final spot in SafeZoneService.safeZones) {
      final center = Offset(
        (spot.x + 0.5) * cellSize,
        (spot.y + 0.5) * cellSize,
      );
      final color = startColors[spot] ?? LudoColors.textMedium;

      // Glow circle
      canvas.drawCircle(
        center,
        cellSize * 0.42,
        Paint()
          ..color = color.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill,
      );

      // Visible outline for the safe spot cell itself
      final outlinePaint = Paint()
        ..color = const Color(0xFFAAA7AD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRect(
        Rect.fromLTWH(spot.x * cellSize, spot.y * cellSize, cellSize, cellSize),
        outlinePaint,
      );

      // Darker star icon: lerp color with black to make it darker and more visible
      final starColor = color == LudoColors.textMedium
          ? const Color(0xFF333333)
          : Color.lerp(color, Colors.black, 0.6)!;

      // Draw star fill with some opacity
      _drawStar(canvas, center, cellSize * 0.28, Paint()
        ..color = starColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
      );

      // Draw star outline (darker)
      _drawStar(canvas, center, cellSize * 0.28, Paint()
        ..color = starColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double outerR, Paint paint) {
    const numPoints = 5;
    final innerR = outerR * 0.5;
    final path = Path();
    var angle = -pi / 2;

    for (var i = 0; i < numPoints * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += pi / numPoints;
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ── Tokens ──────────────────────────────────────────────────────────────

  void _drawTokens(Canvas canvas, Size size, double cellSize) {
    final currentPlayerId =
        currentPlayerIndex >= 0 && currentPlayerIndex < players.length
            ? players[currentPlayerIndex].id
            : null;

    // Group all tokens of all players by their board position
    final Map<BoardPosition, List<Token>> positionTokens = {};
    // Map to find owner player for each token
    final Map<Token, Player> tokenPlayer = {};

    for (final player in players) {
      for (final token in player.tokens) {
        if (token.position != null) {
          positionTokens.putIfAbsent(token.position!, () => []).add(token);
          tokenPlayer[token] = player;
        }
      }
    }

    for (final entry in positionTokens.entries) {
      final pos = entry.key;
      final tokensAtPos = entry.value;

      final isHome = tokensAtPos.first.isHome;
      if (isHome) {
        // In the home yard, draw tokens in their respective slots individually without stacking
        for (final token in tokensAtPos) {
          final player = tokenPlayer[token]!;
          final center = Offset(
            (pos.x + 0.5) * cellSize,
            (pos.y + 0.5) * cellSize,
          );

          _draw3DToken(
            canvas,
            center,
            cellSize * 0.38,
            player.color,
            validTokens.contains(token),
            currentPlayerId == player.id,
            count: 1,
          );
        }
      } else {
        // On the path
        // Check if all tokens at this cell belong to the same player
        final firstTokenOwner = tokenPlayer[tokensAtPos.first]!;
        final allSameOwner = tokensAtPos.every((t) => tokenPlayer[t]?.id == firstTokenOwner.id);

        if (allSameOwner) {
          // Stacked same-player tokens: draw as a single unit at the cell center with a number badge
          final center = Offset(
            (pos.x + 0.5) * cellSize,
            (pos.y + 0.5) * cellSize,
          );

          final isOnPath = !tokensAtPos.first.isHome && !tokensAtPos.first.isFinished;
          final radius = isOnPath ? cellSize * 0.26 : cellSize * 0.38; // Smaller radius on path

          _draw3DToken(
            canvas,
            center,
            radius,
            firstTokenOwner.color,
            validTokens.any((vt) => tokensAtPos.any((t) => t.id == vt.id)),
            currentPlayerId == firstTokenOwner.id,
            count: tokensAtPos.length,
          );
        } else {
          // Different players coexisting (on safe cell): draw overlapping with offset
          final count = tokensAtPos.length;
          for (var idx = 0; idx < count; idx++) {
            final token = tokensAtPos[idx];
            final player = tokenPlayer[token]!;
            var center = Offset(
              (pos.x + 0.5) * cellSize,
              (pos.y + 0.5) * cellSize,
            );
            final off = idx * cellSize * 0.1;
            center = center + Offset(-off, -off);

            final isOnPath = !token.isHome && !token.isFinished;
            final radius = isOnPath ? cellSize * 0.26 : cellSize * 0.38;

            _draw3DToken(
              canvas,
              center,
              radius,
              player.color,
              validTokens.contains(token),
              currentPlayerId == player.id,
              count: 1,
            );
          }
        }
      }
    }

    _drawCaptureOverlay(canvas, cellSize);
  }

  void _draw3DToken(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    bool isValid,
    bool isCurrentPlayer, {
    int count = 1,
  }) {
    // Shadow (softer shadow on light backgrounds)
    canvas.drawCircle(
      center + const Offset(1.5, 3),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );

    // Base gradient (3D sphere effect)
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      radius: 1.0,
      colors: [
        Color.lerp(color, Colors.white, 0.4)!,
        color,
        Color.lerp(color, Colors.black, 0.3)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      ),
    );

    // Specular highlight
    canvas.drawCircle(
      center + Offset(-radius * 0.25, -radius * 0.25),
      radius * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Ring border (subtle dark ring instead of white)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Valid move glow pulse
    if (isValid) {
      final glowR = radius * (1.25 + validPulse * 0.2);
      canvas.drawCircle(
        center,
        glowR,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25 + validPulse * 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      canvas.drawCircle(
        center,
        glowR + radius * 0.15,
        Paint()
          ..color = color.withValues(alpha: 0.15 + validPulse * 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Current player inner dot
    if (isCurrentPlayer) {
      canvas.drawCircle(
        center,
        radius * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }

    // Stacked count badge if count > 1
    if (count > 1) {
      final badgeCenter = center + Offset(radius * 0.7, -radius * 0.7);
      final badgeRadius = radius * 0.45;

      // Shadow
      canvas.drawCircle(
        badgeCenter + const Offset(1, 1),
        badgeRadius,
        Paint()..color = Colors.black.withValues(alpha: 0.3),
      );

      // Badge background
      canvas.drawCircle(
        badgeCenter,
        badgeRadius,
        Paint()..color = const Color(0xFF7C4DFF), // Premium purple
      );

      // Border
      canvas.drawCircle(
        badgeCenter,
        badgeRadius,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Count number text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$count',
          style: TextStyle(
            fontSize: badgeRadius * 1.3,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        badgeCenter - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  // ── Capture Overlay ─────────────────────────────────────────────────────

  void _drawCaptureOverlay(Canvas canvas, double cellSize) {
    if (captureEffect == null) return;

    final effect = captureEffect!;
    final startCenter = Offset(
      (effect.position.x + 0.5) * cellSize,
      (effect.position.y + 0.5) * cellSize,
    );

    final tokenColor = players
        .firstWhere(
          (p) => p.id == effect.playerId,
          orElse: () => players.isNotEmpty
              ? players.first
              : Player(id: 0, color: Colors.red, tokens: const [], path: const []),
        )
        .color;

    final burstAlpha = (1 - captureProgress).clamp(0.0, 1.0);

    // Burst ring (subtle dark burst ring on light mode)
    canvas.drawCircle(
      startCenter,
      cellSize * (0.35 + 0.4 * burstAlpha),
      Paint()
        ..color = Colors.black.withValues(alpha: burstAlpha * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Burst rays
    final burstPaint = Paint()
      ..color = tokenColor.withValues(alpha: burstAlpha * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 8; i++) {
      final angle = (pi * 2 / 8) * i;
      final dir = Offset(cos(angle), sin(angle));
      canvas.drawLine(
        startCenter + dir * cellSize * (0.85 + burstAlpha * 0.35),
        startCenter + dir * cellSize * (1.5 + burstAlpha * 0.75),
        burstPaint,
      );
    }

    // Draw all returning tokens in the capture effect list
    for (final capToken in effect.tokens) {
      final homeCenter = Offset(
        (capToken.homePosition.x + 0.5) * cellSize,
        (capToken.homePosition.y + 0.5) * cellSize,
      );

      final currentCenter =
          Offset.lerp(startCenter, homeCenter, captureProgress) ?? homeCenter;
      final returnRadius =
          cellSize * (0.32 - 0.10 * captureProgress).clamp(0.18, 0.32);

      // Trail
      final trail = Path()
        ..moveTo(startCenter.dx, startCenter.dy)
        ..quadraticBezierTo(
          (startCenter.dx + homeCenter.dx) / 2,
          (startCenter.dy + homeCenter.dy) / 2 - cellSize * 0.6,
          homeCenter.dx,
          homeCenter.dy,
        );
      canvas.drawPath(
        trail,
        Paint()
          ..color = tokenColor.withValues(alpha: 0.28 * burstAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - captureProgress),
      );

      // Moving token
      _draw3DToken(canvas, currentCenter, returnRadius, tokenColor, false, false, count: 1);
    }
  }

  // ── Repaint ─────────────────────────────────────────────────────────────

  @override
  bool shouldRepaint(ModernBoardPainter old) {
    return old.players != players ||
        old.currentPlayerIndex != currentPlayerIndex ||
        old.validTokens != validTokens ||
        old.captureEffect != captureEffect ||
        old.captureProgress != captureProgress ||
        old.validPulse != validPulse;
  }
}
