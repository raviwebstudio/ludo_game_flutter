import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// A 3D-looking dice that rotates and tumbles continuously, cycling faces.
class AnimatedDice extends StatefulWidget {
  final double size;
  final bool isRolling;

  const AnimatedDice({this.size = 120, this.isRolling = true, super.key});

  @override
  State<AnimatedDice> createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _scale;
  int _currentFace = 5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _rotation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.addListener(() {
      final segment = (_controller.value * 12).floor();
      final newFace = (segment % 6) + 1;
      if (newFace != _currentFace) {
        setState(() {
          _currentFace = newFace;
        });
      }
    });

    if (widget.isRolling) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedDice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling != oldWidget.isRolling) {
      if (widget.isRolling) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Transform.rotate(
            angle: _rotation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              LudoColors.cyan.withValues(alpha: 0.3),
              LudoColors.cyan.withValues(alpha: 0.1),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            width: widget.size * 0.55,
            height: widget.size * 0.55,
            padding: EdgeInsets.all(widget.size * 0.08),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(widget.size * 0.12),
              border: Border.all(
                color: LudoColors.cyan,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: LudoColors.cyan.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: _buildDiceDots(_currentFace, widget.size * 0.06),
          ),
        ),
      ),
    );
  }

  Widget _buildDiceDots(int face, double dotSize) {
    switch (face) {
      case 1:
        return Center(child: _dot(dotSize));
      case 2:
        return Stack(
          children: [
            Align(alignment: Alignment.topLeft, child: _dot(dotSize)),
            Align(alignment: Alignment.bottomRight, child: _dot(dotSize)),
          ],
        );
      case 3:
        return Stack(
          children: [
            Align(alignment: Alignment.topLeft, child: _dot(dotSize)),
            Align(alignment: Alignment.center, child: _dot(dotSize)),
            Align(alignment: Alignment.bottomRight, child: _dot(dotSize)),
          ],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_dot(dotSize), _dot(dotSize)],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_dot(dotSize), _dot(dotSize)],
            ),
          ],
        );
      case 5:
        return Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_dot(dotSize), _dot(dotSize)],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_dot(dotSize), _dot(dotSize)],
                ),
              ],
            ),
            Align(alignment: Alignment.center, child: _dot(dotSize)),
          ],
        );
      case 6:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_dot(dotSize), _dot(dotSize), _dot(dotSize)],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_dot(dotSize), _dot(dotSize), _dot(dotSize)],
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _dot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );
  }
}
