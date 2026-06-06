/// Duration constants for every animation in Ludo Elite.
class LudoAnimations {
  LudoAnimations._();

  // ── Screen‑Level ──
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration screenTransition = Duration(milliseconds: 300);

  // ── Game ──
  static const Duration diceDuration = Duration(milliseconds: 1200);
  static const Duration tokenMovement = Duration(milliseconds: 120);
  static const Duration captureAnimation = Duration(milliseconds: 500);

  // ── Micro‑Interactions ──
  static const Duration buttonTap = Duration(milliseconds: 100);
  static const Duration cardEntrance = Duration(milliseconds: 300);
  static const Duration bounceAnimation = Duration(milliseconds: 200);
  static const Duration glowPulse = Duration(milliseconds: 1200);
  static const Duration fadeIn = Duration(milliseconds: 500);

  // ── Stagger Delays ──
  static const Duration staggerDelay = Duration(milliseconds: 100);
}
