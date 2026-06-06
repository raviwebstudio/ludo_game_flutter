import 'package:flutter/animation.dart';

/// Helper factories for common animation setups.
class AnimationService {
  AnimationService._();

  /// Create a basic [AnimationController].
  static AnimationController createController({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return AnimationController(duration: duration, vsync: vsync);
  }

  /// Wrap a controller in a [CurvedAnimation].
  static Animation<double> createCurvedAnimation({
    required AnimationController controller,
    Curve curve = Curves.easeInOut,
  }) {
    return CurvedAnimation(parent: controller, curve: curve);
  }

  /// Create a slide [Animation] (Offset tween).
  static Animation<Offset> createSlideAnimation({
    required Animation<double> parent,
    Offset begin = const Offset(0, -1),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(parent);
  }

  /// Create a scale tween on a controller.
  static Animation<double> createScaleAnimation({
    required Animation<double> parent,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(begin: begin, end: end).animate(parent);
  }
}
