import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/haptic_service.dart';

/// A premium 3D CustomPaint dice widget with spin, bounce, and glow animations.
class DiceWidget extends StatefulWidget {
  final int? value;
  final Future<int?> Function() onRoll;
  final bool enabled;
  final bool isActivePlayer;
  final Color? activeColor;
  final double size;
  final bool soundEnabled;

  const DiceWidget({
    super.key,
    required this.value,
    required this.onRoll,
    required this.enabled,
    this.isActivePlayer = false,
    this.activeColor,
    this.size = 80,
    this.soundEnabled = true,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with TickerProviderStateMixin {
  static const Duration _rollDuration = Duration(milliseconds: 1200);
  static const Duration _faceChange = Duration(milliseconds: 75);
  static const List<int> _faces = [1, 5, 2, 6, 3, 4, 2, 5, 1, 6, 4, 3, 6, 2, 1, 5];

  late final AnimationController _rollCtrl;
  late final AnimationController _bounceCtrl;
  late final AnimationController _glowCtrl;
  late final Animation<double> _rollCurve;
  late final Animation<double> _bounceScale;
  late final Tween<double> _rotationTween;
  late final Tween<double> _rollScaleTween;

  Timer? _faceTimer;
  int _faceIdx = 0;
  int? _displayValue;
  int? _lastSettled;
  bool _isRolling = false;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value ?? 1; // Default to 1 instead of null
    _lastSettled = widget.value ?? 1;

    _rollCtrl = AnimationController(vsync: this, duration: _rollDuration);
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rollCurve = CurvedAnimation(
      parent: _rollCtrl,
      curve: Curves.easeInOutCubic,
    );
    _bounceScale = Tween<double>(begin: 1, end: 1.18).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut),
    );
    _rotationTween = Tween<double>(begin: 0, end: math.pi * 4);
    _rollScaleTween = Tween<double>(begin: 1, end: 1.08);
  }

  @override
  void didUpdateWidget(covariant DiceWidget old) {
    super.didUpdateWidget(old);
    if (_isRolling) return;

    if (widget.value == null) {
      // Do NOT clear _displayValue and _lastSettled to null.
      // This keeps the last rolled value visible on the board and avoids the white flash.
      return;
    }

    final v = widget.value;
    if (v != null && v != old.value && v != _lastSettled) {
      _showFinal(v);
    }
  }

  @override
  void dispose() {
    _faceTimer?.cancel();
    _rollCtrl.dispose();
    _bounceCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!widget.enabled || _isRolling) return;

    unawaited(HapticService.mediumTap());

    setState(() {
      _isRolling = true;
      _faceIdx = 0;
      _displayValue = _faces.first;
    });

    _startFaceTimer();

    try {
      await _rollCtrl.forward(from: 0);
      _stopFaceTimer();
      _rollCtrl.reset();

      final result = await widget.onRoll();
      if (!mounted) return;

      setState(() => _isRolling = false);
      if (result != null) _showFinal(result);
    } catch (_) {
      if (!mounted) return;
      _stopFaceTimer();
      _rollCtrl.reset();
      setState(() {
        _isRolling = false;
        _displayValue = widget.value ?? 1;
      });
    }
  }

  void _startFaceTimer() {
    _faceTimer?.cancel();
    _faceTimer = Timer.periodic(_faceChange, (_) {
      if (!mounted) return;
      setState(() {
        _faceIdx = (_faceIdx + 1) % _faces.length;
        _displayValue = _faces[_faceIdx];
      });
    });
  }

  void _stopFaceTimer() {
    _faceTimer?.cancel();
    _faceTimer = null;
  }

  void _showFinal(int v) {
    if (!mounted) return;
    setState(() {
      _displayValue = v;
      _lastSettled = v;
    });
    unawaited(HapticService.selection());
    unawaited(_bounceCtrl.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && !_isRolling;
    final faceValue = _displayValue ?? widget.value ?? 1;
    final activeColor = widget.activeColor ?? LudoColors.purple;

    return GestureDetector(
      onTap: canTap ? _handleTap : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rollCtrl,
          _bounceCtrl,
          _glowCtrl,
        ]),
        builder: (context, child) {
          final rotation =
              _isRolling ? _rotationTween.evaluate(_rollCurve) : 0.0;
          final rollScale =
              _isRolling ? _rollScaleTween.evaluate(_rollCurve) : 1.0;
          final scale = rollScale * _bounceScale.value;
          final glowOpacity = _glowCtrl.value;

          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.size * 0.18),
              boxShadow: [
                // Bottom shadow for 3D depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: widget.size * 0.15,
                  offset: Offset(0, widget.size * 0.06),
                  spreadRadius: widget.size * 0.01,
                ),
                // Colored glow when active
                if (widget.isActivePlayer)
                  BoxShadow(
                    color: activeColor.withValues(
                      alpha: 0.2 + glowOpacity * 0.15,
                    ),
                    blurRadius: widget.size * 0.3,
                    spreadRadius: widget.size * 0.02,
                  ),
              ],
            ),
            child: CustomPaint(
              painter: _Dice3DPainter(
                faceValue: faceValue,
                cornerRadius: widget.size * 0.18,
                isEnabled: widget.enabled,
                rotation: rotation,
                scale: scale,
              ),
              size: Size(widget.size, widget.size),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter that draws a 3D-looking dice with proper dot pips.
class _Dice3DPainter extends CustomPainter {
  final int faceValue;
  final double cornerRadius;
  final bool isEnabled;
  final double rotation;
  final double scale;

  _Dice3DPainter({
    required this.faceValue,
    required this.cornerRadius,
    required this.isEnabled,
    required this.rotation,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

    // --- 3D Body ---
    // Bottom face (dark edge for depth)
    final bottomEdge = RRect.fromRectAndRadius(
      rect.translate(0, size.height * 0.04),
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(
      bottomEdge,
      Paint()..color = const Color(0xFFB0B0B0),
    );

    // Main face gradient (white to light grey for 3D look)
    final faceGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFFDFDFD),
        const Color(0xFFF0F0F0),
        const Color(0xFFE8E8E8),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    canvas.drawRRect(
      rRect,
      Paint()..shader = faceGradient.createShader(rect),
    );

    // Top-left highlight for 3D shine
    final highlightGradient = RadialGradient(
      center: const Alignment(-0.6, -0.6),
      radius: 1.2,
      colors: [
        Colors.white.withValues(alpha: 0.7),
        Colors.white.withValues(alpha: 0.0),
      ],
    );
    canvas.drawRRect(
      rRect,
      Paint()..shader = highlightGradient.createShader(rect),
    );

    // Subtle border
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = const Color(0xFFD0D0D0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // --- Draw Pips ---
    if (faceValue < 1 || faceValue > 6) {
      _drawPlaceholderIcon(canvas, size);
      return;
    }

    final pipColor = isEnabled
        ? const Color(0xFF2C3E50)
        : const Color(0xFF95A5A6);
    final pipRadius = size.width * 0.085;
    final pipPaint = Paint()
      ..color = pipColor
      ..style = PaintingStyle.fill;

    // Pip shadow
    final pipShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);
    canvas.scale(scale);
    canvas.translate(-cx, -cy);

    final positions = _getPipPositions(faceValue, size);
    for (final pos in positions) {
      // Draw pip shadow
      canvas.drawCircle(
        pos + Offset(size.width * 0.01, size.width * 0.015),
        pipRadius,
        pipShadowPaint,
      );
      // Draw pip
      canvas.drawCircle(pos, pipRadius, pipPaint);
      // Draw pip highlight
      canvas.drawCircle(
        pos + Offset(-pipRadius * 0.25, -pipRadius * 0.25),
        pipRadius * 0.35,
        Paint()..color = Colors.white.withValues(alpha: 0.3),
      );
    }
    canvas.restore();
  }

  List<Offset> _getPipPositions(int value, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final offset = size.width * 0.25; // Distance from center for corner pips

    final topLeft = Offset(cx - offset, cy - offset);
    final topRight = Offset(cx + offset, cy - offset);
    final midLeft = Offset(cx - offset, cy);
    final midRight = Offset(cx + offset, cy);
    final bottomLeft = Offset(cx - offset, cy + offset);
    final bottomRight = Offset(cx + offset, cy + offset);
    final center = Offset(cx, cy);

    switch (value) {
      case 1:
        return [center];
      case 2:
        return [topRight, bottomLeft];
      case 3:
        return [topRight, center, bottomLeft];
      case 4:
        return [topLeft, topRight, bottomLeft, bottomRight];
      case 5:
        return [topLeft, topRight, center, bottomLeft, bottomRight];
      case 6:
        return [topLeft, topRight, midLeft, midRight, bottomLeft, bottomRight];
      default:
        return [];
    }
  }

  void _drawPlaceholderIcon(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFFBDBDBD),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_Dice3DPainter oldDelegate) {
    return oldDelegate.faceValue != faceValue ||
        oldDelegate.isEnabled != isEnabled ||
        oldDelegate.rotation != rotation ||
        oldDelegate.scale != scale;
  }
}
