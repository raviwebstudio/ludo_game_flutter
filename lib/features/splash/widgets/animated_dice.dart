import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// A dice icon inside a glowing mint‑green circle — the Ludo Elite logo mark.
class AnimatedDice extends StatefulWidget {
  final double size;

  const AnimatedDice({this.size = 120, super.key});

  @override
  State<AnimatedDice> createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              LudoColors.mintGreenLight.withValues(alpha: 0.4),
              LudoColors.mintGreen.withValues(alpha: 0.15),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            width: widget.size * 0.55,
            height: widget.size * 0.55,
            decoration: BoxDecoration(
              color: LudoColors.mintGreen.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(widget.size * 0.15),
              border: Border.all(
                color: LudoColors.mintGreen.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: _buildDiceDots(widget.size * 0.06),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiceDots(double dotSize) {
    // 5‑face pattern (⚄)
    return Padding(
      padding: EdgeInsets.all(dotSize * 1.2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(dotSize),
              SizedBox(width: dotSize * 1.5),
              _dot(dotSize),
            ],
          ),
          SizedBox(height: dotSize),
          _dot(dotSize),
          SizedBox(height: dotSize),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(dotSize),
              SizedBox(width: dotSize * 1.5),
              _dot(dotSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
    );
  }
}
