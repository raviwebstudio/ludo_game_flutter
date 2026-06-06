import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';

/// A premium dice widget with lavender tint, purple glow, spin animation,
/// and bounce settle — matching the Ludo Elite reference.
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

  Timer? _faceTimer;
  int _faceIdx = 0;
  int? _displayValue;
  int? _lastSettled;
  bool _isRolling = false;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
    _lastSettled = widget.value;

    _rollCtrl = AnimationController(vsync: this, duration: _rollDuration);
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    _rollCurve = CurvedAnimation(
        parent: _rollCtrl, curve: Curves.easeInOutCubic);
    _bounceScale = Tween<double>(begin: 1, end: 1.18).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(covariant DiceWidget old) {
    super.didUpdateWidget(old);
    if (_isRolling) return;

    if (widget.value == null && old.value != null) {
      setState(() {
        _displayValue = null;
        _lastSettled = null;
      });
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

    unawaited(HapticFeedback.mediumImpact());

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
        _displayValue = widget.value;
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
    unawaited(HapticFeedback.selectionClick());
    unawaited(_bounceCtrl.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && !_isRolling;
    final face = _displayValue ?? widget.value;

    return GestureDetector(
      onTap: canTap ? _handleTap : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rollCtrl, _bounceCtrl, _glowCtrl]),
        builder: (context, child) {
          final rotation = _isRolling
              ? Tween<double>(begin: 0, end: math.pi * 4)
                  .evaluate(_rollCurve)
              : 0.0;
          final rollScale = _isRolling
              ? Tween<double>(begin: 1, end: 1.08).evaluate(_rollCurve)
              : 1.0;
          final scale = rollScale * _bounceScale.value;

          return Transform.rotate(
            angle: rotation,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            // Lavender tint
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF0E6FF),
                const Color(0xFFE8D8F8),
              ],
            ),
            borderRadius: BorderRadius.circular(widget.size * 0.22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              if (widget.isActivePlayer)
                BoxShadow(
                  color: LudoColors.purple.withValues(
                    alpha: 0.3 + 0.15 * _glowCtrl.value,
                  ),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
            ],
          ),
          child: face != null
              ? Center(child: _buildDiceFace(face))
              : Center(
                  child: Icon(
                    Icons.casino_outlined,
                    color: LudoColors.purple.withValues(alpha: 0.4),
                    size: widget.size * 0.45,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDiceFace(int value) {
    final dotSize = widget.size * 0.12;
    final spacing = widget.size * 0.06;
    final dotColor = LudoColors.purpleDark;

    Widget dot() => Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        );

    Widget empty() => SizedBox(width: dotSize, height: dotSize);

    // Build standard dice patterns
    List<Widget> rows;
    switch (value) {
      case 1:
        rows = [
          Row(mainAxisSize: MainAxisSize.min, children: [empty(), empty(), empty()]),
          Row(mainAxisSize: MainAxisSize.min, children: [empty(), dot(), empty()]),
          Row(mainAxisSize: MainAxisSize.min, children: [empty(), empty(), empty()]),
        ];
        break;
      case 2:
        rows = [
          Row(mainAxisSize: MainAxisSize.min, children: [empty(), empty(), dot()]),
          Row(mainAxisSize: MainAxisSize.min, children: [empty(), empty(), empty()]),
          Row(mainAxisSize: MainAxisSize.min, children: [dot(), empty(), empty()]),
        ];
        break;
      case 3:
        rows = [
          Row(mainAxisSize: MainAxisSize.min, children: [empty(), empty(), dot()]),
          Row(mainAxisSize: MainAxisSize.min, children: [empty(), dot(), empty()]),
          Row(mainAxisSize: MainAxisSize.min, children: [dot(), empty(), empty()]),
        ];
        break;
      case 4:
        rows = [
          Row(mainAxisSize: MainAxisSize.min, children: [dot(), empty(), dot()]),
          Row(mainAxisSize: MainAxisSize.min, children: [empty(), empty(), empty()]),
          Row(mainAxisSize: MainAxisSize.min, children: [dot(), empty(), dot()]),
        ];
        break;
      case 5:
        rows = [
          Row(mainAxisSize: MainAxisSize.min, children: [dot(), empty(), dot()]),
          Row(mainAxisSize: MainAxisSize.min, children: [empty(), dot(), empty()]),
          Row(mainAxisSize: MainAxisSize.min, children: [dot(), empty(), dot()]),
        ];
        break;
      case 6:
      default:
        rows = [
          Row(mainAxisSize: MainAxisSize.min, children: [dot(), empty(), dot()]),
          Row(mainAxisSize: MainAxisSize.min, children: [dot(), empty(), dot()]),
          Row(mainAxisSize: MainAxisSize.min, children: [dot(), empty(), dot()]),
        ];
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows
          .map((row) => Padding(
                padding: EdgeInsets.symmetric(vertical: spacing * 0.5),
                child: row,
              ))
          .toList(),
    );
  }
}
