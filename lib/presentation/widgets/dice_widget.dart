import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ludo_game/core/constants/colors.dart';

class DiceWidget extends StatefulWidget {
  final int? value;
  final Future<int?> Function() onRoll;
  final bool enabled;
  final bool isActivePlayer;
  final Color? activeColor;
  final double size;
  final bool soundEnabled;
  final VoidCallback? onRollStart;
  final VoidCallback? onRollTick;
  final ValueChanged<int>? onRollComplete;

  const DiceWidget({
    super.key,
    required this.value,
    required this.onRoll,
    required this.enabled,
    this.isActivePlayer = false,
    this.activeColor,
    this.size = 60,
    this.soundEnabled = true,
    this.onRollStart,
    this.onRollTick,
    this.onRollComplete,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with TickerProviderStateMixin {
  static const Duration _rollDuration = Duration(milliseconds: 1200);
  static const Duration _faceChangeDuration = Duration(milliseconds: 75);
  static const Duration _glowDuration = Duration(milliseconds: 1200);
  static const List<int> _rollingFaces = [
    1,
    5,
    2,
    6,
    3,
    4,
    2,
    5,
    1,
    6,
    4,
    3,
    6,
    2,
    1,
    5,
  ];
  static const List<String> _faceIcons = [
    '⚀',
    '⚁',
    '⚂',
    '⚃',
    '⚄',
    '⚅',
  ];

  late final AnimationController _rollController;
  late final AnimationController _bounceController;
  late final AnimationController _glowController;
  late final Animation<double> _rollCurve;
  late final Animation<double> _bounceScale;
  late final Tween<double> _rotationTween;
  late final Tween<double> _rollScaleTween;

  Timer? _faceTimer;
  int _faceIndex = 0;
  int? _displayValue;
  int? _lastSettledValue;
  bool _isRolling = false;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
    _lastSettledValue = widget.value;
    _rollController = AnimationController(
      vsync: this,
      duration: _rollDuration,
    );
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: _glowDuration,
    )..repeat(reverse: true);

    _rollCurve = CurvedAnimation(
      parent: _rollController,
      curve: Curves.easeInOutCubic,
    );
    _bounceScale = Tween<double>(begin: 1, end: 1.18).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.elasticOut,
      ),
    );
    _rotationTween = Tween<double>(begin: 0, end: math.pi * 4);
    _rollScaleTween = Tween<double>(begin: 1, end: 1.08);
  }

  @override
  void didUpdateWidget(covariant DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isRolling) return;

    if (widget.value == null && oldWidget.value != null) {
      setState(() {
        _displayValue = null;
        _lastSettledValue = null;
      });
      return;
    }

    final newValue = widget.value;
    if (newValue != null &&
        newValue != oldWidget.value &&
        newValue != _lastSettledValue) {
      _showFinalValue(newValue);
    }
  }

  @override
  void dispose() {
    _faceTimer?.cancel();
    _rollController.dispose();
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!widget.enabled || _isRolling) return;

    widget.onRollStart?.call();
    unawaited(HapticFeedback.mediumImpact());
    if (widget.soundEnabled) {
      unawaited(SystemSound.play(SystemSoundType.click));
    }

    setState(() {
      _isRolling = true;
      _faceIndex = 0;
      _displayValue = _rollingFaces.first;
    });

    _startFaceTimer();

    try {
      await _rollController.forward(from: 0);
      _stopFaceTimer();
      _rollController.reset();

      final rolledValue = await widget.onRoll();
      if (!mounted) return;

      setState(() {
        _isRolling = false;
      });

      if (rolledValue != null) {
        _showFinalValue(rolledValue);
        widget.onRollComplete?.call(rolledValue);
      }
    } catch (_) {
      if (!mounted) return;
      _stopFaceTimer();
      _rollController.reset();
      setState(() {
        _isRolling = false;
        _displayValue = widget.value;
      });
    }
  }

  void _startFaceTimer() {
    _faceTimer?.cancel();
    _faceTimer = Timer.periodic(_faceChangeDuration, (_) {
      if (!mounted) return;

      setState(() {
        _faceIndex = (_faceIndex + 1) % _rollingFaces.length;
        _displayValue = _rollingFaces[_faceIndex];
      });

      widget.onRollTick?.call();
      if (widget.soundEnabled && _faceIndex.isEven) {
        unawaited(SystemSound.play(SystemSoundType.click));
      }
    });
  }

  void _stopFaceTimer() {
    _faceTimer?.cancel();
    _faceTimer = null;
  }

  void _showFinalValue(int value) {
    if (!mounted) return;

    setState(() {
      _displayValue = value;
      _lastSettledValue = value;
    });
    unawaited(HapticFeedback.selectionClick());
    unawaited(_bounceController.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && !_isRolling;
    final faceValue = _displayValue ?? widget.value;
    final activeColor = widget.activeColor ?? Colors.green;

    return GestureDetector(
      onTap: canTap ? _handleTap : null,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [LudoColors.darkNavyLight, LudoColors.darkNavy],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(widget.size * 0.2),
          border: Border.all(
            color: activeColor.withValues(alpha: 0.28),
            width: widget.size * 0.06,
          ),
          boxShadow: [
            BoxShadow(
              color: LudoColors.shadow,
              blurRadius: widget.size * 0.12,
              spreadRadius: widget.size * 0.03,
            ),
          ],
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _rollController,
              _bounceController,
              _glowController,
            ]),
            builder: (context, child) {
              final rotation =
                  _isRolling ? _rotationTween.evaluate(_rollCurve) : 0.0;
              final rollScale =
                  _isRolling ? _rollScaleTween.evaluate(_rollCurve) : 1.0;
              final scale = rollScale * _bounceScale.value;
              return Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              );
            },
            child: faceValue != null
                ? Text(
                    _faceIcons[(faceValue - 1).clamp(0, 5)],
                    style: TextStyle(
                      fontSize: widget.size * 0.5,
                      fontWeight: FontWeight.w700,
                      color: widget.enabled ? LudoColors.textLight : Colors.grey[400],
                    ),
                  )
                : Icon(
                    Icons.casino_outlined,
                    color: Colors.grey[400],
                    size: widget.size * 0.45,
                  ),
          ),
        ),
      ),
    );
  }
}
