import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/animations.dart';
import '../../../core/constants/colors.dart';
import '../widgets/animated_dice.dart';
import '../widgets/loading_bar.dart';

/// Splash screen matching the Ludo Elite reference design.
///
/// Dark navy‑to‑purple gradient, mint‑green dice logo, animated loading bar,
/// and floating particle dots.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(LudoAnimations.splashDuration + const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/auth');
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0ECFF), // soft purple tint
              Color(0xFFF5F6FA), // cool off-white
              Color(0xFFEEEFF5), // slightly darker cool gray
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Floating particles ──
            ..._buildParticles(size.width, size.height),

            // ── Main content ──
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Dice logo
                    const AnimatedDice(size: 140)
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .scale(begin: const Offset(0.5, 0.5), duration: 800.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 12),

                    // "Fetching Arena..." label
                    Text(
                      'Fetching Arena...',
                      style: TextStyle(
                        fontSize: 14,
                        color: LudoColors.textMedium,
                        letterSpacing: 1,
                      ),
                    ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                    const SizedBox(height: 32),

                    // Loading bar
                    LoadingBar(
                      duration: LudoAnimations.splashDuration,
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                    const SizedBox(height: 40),

                    // "LUDO" title
                    Text(
                      'LUDO',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: LudoColors.textLight,
                        letterSpacing: 8,
                        shadows: [
                          Shadow(
                            color: LudoColors.purple.withValues(alpha: 0.35),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 600.ms)
                        .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOut),

                    // "ELITE" subtitle
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [LudoColors.purpleLight, LudoColors.mintGreen],
                      ).createShader(bounds),
                      child: const Text(
                        'ELITE',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 12,
                          color: Colors.white,
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms, duration: 600.ms)
                        .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOut),

                    const SizedBox(height: 16),

                    // Tagline
                    Text(
                      'THE NEW STANDARD OF PLAY',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: LudoColors.mintGreen.withValues(alpha: 0.8),
                        letterSpacing: 3,
                      ),
                    ).animate().fadeIn(delay: 800.ms, duration: 600.ms),

                    const Spacer(flex: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generates subtle floating dot particles across the screen.
  List<Widget> _buildParticles(double width, double height) {
    final rng = Random(42);
    return List.generate(12, (i) {
      final left = rng.nextDouble() * width;
      final top = rng.nextDouble() * height;
      final size = 3.0 + rng.nextDouble() * 5;
      final opacity = 0.15 + rng.nextDouble() * 0.25;
      final delay = (rng.nextDouble() * 1500).toInt();

      return Positioned(
        left: left,
        top: top,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LudoColors.mintGreen.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                color: LudoColors.mintGreen.withValues(alpha: opacity * 0.5),
                blurRadius: size * 2,
              ),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(delay: Duration(milliseconds: delay), duration: 1500.ms)
            .then()
            .fadeOut(duration: 1500.ms),
      );
    });
  }
}
