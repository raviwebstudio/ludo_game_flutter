import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// An animated progress bar that fills from left to right over [duration].
class LoadingBar extends StatefulWidget {
  final Duration duration;
  final double width;
  final double height;

  const LoadingBar({
    required this.duration,
    this.width = 260,
    this.height = 6,
    super.key,
  });

  @override
  State<LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fill;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _fill = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fill,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(widget.height),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: widget.width * _fill.value,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [LudoColors.mintGreen, LudoColors.mintGreenLight],
                ),
                borderRadius: BorderRadius.circular(widget.height),
                boxShadow: [
                  BoxShadow(
                    color: LudoColors.mintGreen.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
