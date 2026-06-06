import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/board_position.dart';
import '../../../domain/services/safe_zones.dart';
import '../../../presentation/bloc/game_bloc.dart';

/// A dark‑themed board painter matching the Ludo Elite reference designs.
///
/// Uses the same 15×15 coordinate system as the original [BoardPainter],
/// but renders with a premium dark aesthetic: dark board background, coloured
/// quadrant homes with rounded slots, 3‑D sphere tokens, and glowing effects.
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

    _drawBackground(canvas, size, cellSize);
    _drawPlayerHomes(canvas, size, cellSize);
    _drawCenterPaths(canvas, size, cellSize);
    _drawHomeStretch(canvas, size, cellSize);
    _drawSafeSpots(canvas, size, cellSize);
    _drawTokens(canvas, size, cellSize);
  }

  // ── Background ──────────────────────────────────────────────────────────

  void _drawBackground(Canvas canvas, Size size, double cellSize) {
    // Dark board background
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFF1A2233),
    );

    // Subtle grid overlay for the path area
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Vertical path columns (6..8)
    for (var x = 6; x <= 9; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, size.height),
        gridPaint,
      );
    }
    // Horizontal path rows (6..8)
    for (var y = 6; y <= 9; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(size.width, y * cellSize),
        gridPaint,
      );
    }

    // Row/column lines inside the path
    for (var i = 0; i <= 15; i++) {
      final pos = i * cellSize;
      // Only draw within path areas
      if (i >= 6 && i <= 9) continue;
      // Vertical inside horizontal path
      canvas.drawLine(Offset(pos, 6 * cellSize), Offset(pos, 9 * cellSize), gridPaint);
      // Horizontal inside vertical path
      canvas.drawLine(Offset(6 * cellSize, pos), Offset(9 * cellSize, pos), gridPaint);
    }
  }

  // ── Player Homes ────────────────────────────────────────────────────────

  void _drawPlayerHomes(Canvas canvas, Size size, double cellSize) {
    final homeSize = 6 * cellSize;
    final positions = [
      Offset.zero,
      Offset(size.width - homeSize, 0),
      Offset(size.width - homeSize, size.height - homeSize),
      Offset(0, size.height - homeSize),
    ];

    for (var i = 0; i < 4; i++) {
      _drawModernHome(canvas, positions[i], homeSize, _playerColor(i), i);
    }
  }

  void _drawModernHome(
    Canvas canvas,
    Offset offset,
    double size,
    Color color,
    int playerIndex,
  ) {
    final rect = Rect.fromLTWH(offset.dx, offset.dy, size, size);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Background
    canvas.drawRRect(
      rr,
      Paint()..color = color.withValues(alpha: 0.18),
    );

    // Border
    canvas.drawRRect(
      rr,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner white box for token slots
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
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // 4 token slot circles
    final slotSize = (size - innerMargin * 2) / 2;
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 2; col++) {
        final cx = offset.dx + innerMargin + slotSize * (col + 0.5);
        final cy = offset.dy + innerMargin + slotSize * (row + 0.5);
        // Dark rounded slot
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
          Paint()..color = const Color(0xFF0A1628),
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

  void _drawCenterPaths(Canvas canvas, Size size, double cellSize) {
    final pathBg = Paint()..color = const Color(0xFF1E2A3E);

    // Vertical path
    canvas.drawRect(
      Rect.fromLTWH(6 * cellSize, 0, 3 * cellSize, size.height),
      pathBg,
    );
    // Horizontal path
    canvas.drawRect(
      Rect.fromLTWH(0, 6 * cellSize, size.width, 3 * cellSize),
      pathBg,
    );

    // Path cell borders
    final cellBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var x = 6; x < 9; x++) {
      for (var y = 0; y < 15; y++) {
        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          cellBorder,
        );
      }
    }
    for (var y = 6; y < 9; y++) {
      for (var x = 0; x < 15; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          cellBorder,
        );
      }
    }
  }

  // ── Home Stretch & Center ───────────────────────────────────────────────

  void _drawHomeStretch(Canvas canvas, Size size, double cellSize) {
    final center = Offset(7.5 * cellSize, 7.5 * cellSize);

    // Center triangles (darker muted tones)
    _drawTriangle(
      canvas,
      Offset(6 * cellSize, 6 * cellSize),
      center,
      Offset(6 * cellSize, 9 * cellSize),
      _playerColor(0),
    );
    _drawTriangle(
      canvas,
      Offset(6 * cellSize, 6 * cellSize),
      center,
      Offset(9 * cellSize, 6 * cellSize),
      _playerColor(1),
    );
    _drawTriangle(
      canvas,
      Offset(9 * cellSize, 6 * cellSize),
      center,
      Offset(9 * cellSize, 9 * cellSize),
      _playerColor(2),
    );
    _drawTriangle(
      canvas,
      Offset(6 * cellSize, 9 * cellSize),
      center,
      Offset(9 * cellSize, 9 * cellSize),
      _playerColor(3),
    );

    // Home stretch coloured paths
    _drawColoredStretch(
        canvas, 1 * cellSize, 7 * cellSize, 5 * cellSize, cellSize, _playerColor(0));
    _drawColoredStretch(
        canvas, 7 * cellSize, 1 * cellSize, cellSize, 5 * cellSize, _playerColor(1));
    _drawColoredStretch(
        canvas, 9 * cellSize, 7 * cellSize, 5 * cellSize, cellSize, _playerColor(2));
    _drawColoredStretch(
        canvas, 7 * cellSize, 9 * cellSize, cellSize, 5 * cellSize, _playerColor(3));
  }

  void _drawTriangle(
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
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawColoredStretch(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    Color color,
  ) {
    final rect = Rect.fromLTWH(x, y, w, h);
    canvas.drawRect(
      rect,
      Paint()..color = color.withValues(alpha: 0.12),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
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
        cellSize * 0.4,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill,
      );

      // Star
      _drawStar(canvas, center, cellSize * 0.28, Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
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

    // Count tokens per position (for stack offsets)
    final Map<BoardPosition, int> tokenCounts = {};
    for (final player in players) {
      for (final token in player.tokens) {
        if (token.position != null) {
          tokenCounts[token.position!] =
              (tokenCounts[token.position!] ?? 0) + 1;
        }
      }
    }

    for (final player in players) {
      for (final token in player.tokens) {
        if (token.position == null) continue;

        var center = Offset(
          (token.position!.x + 0.5) * cellSize,
          (token.position!.y + 0.5) * cellSize,
        );

        final count = tokenCounts[token.position!] ?? 1;
        if (count > 1) {
          final idx = player.tokens.indexOf(token);
          final off = (idx % count) * cellSize * 0.1;
          center = center + Offset(-off, -off);
        }

        _draw3DToken(
          canvas,
          center,
          cellSize * 0.38,
          player.color,
          validTokens.contains(token),
          currentPlayerId == player.id,
        );
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
    bool isCurrentPlayer,
  ) {
    // Shadow
    canvas.drawCircle(
      center + const Offset(1.5, 3),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
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

    // Ring border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
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
  }

  // ── Capture Overlay ─────────────────────────────────────────────────────

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
          (p) => p.id == effect.playerId,
          orElse: () => players.isNotEmpty
              ? players.first
              : Player(id: 0, color: Colors.red, tokens: const [], path: const []),
        )
        .color;

    final currentCenter =
        Offset.lerp(startCenter, homeCenter, captureProgress) ?? homeCenter;
    final returnRadius =
        cellSize * (0.32 - 0.10 * captureProgress).clamp(0.18, 0.32);
    final burstAlpha = (1 - captureProgress).clamp(0.0, 1.0);

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

    // Burst ring
    canvas.drawCircle(
      startCenter,
      cellSize * (0.35 + 0.4 * burstAlpha),
      Paint()
        ..color = Colors.white.withValues(alpha: burstAlpha * 0.8)
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

    // Moving token
    _draw3DToken(canvas, currentCenter, returnRadius, tokenColor, false, false);
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
