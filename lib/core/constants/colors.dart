import 'package:flutter/material.dart';

/// Ludo Elite color palette.
///
/// Dark navy base with vibrant blue accents and classic token colors.
class LudoColors {
  LudoColors._();

  // ── Dark Navy (Main Background) ──
  static const Color darkNavy = Color(0xFF1A2A4A);
  static const Color darkNavyLight = Color(0xFF253B5C);
  static const Color darkNavyDark = Color(0xFF0F1A32);

  // ── Blues (Accents & Interactive) ──
  static const Color brightBlue = Color(0xFF00A8FF);
  static const Color softBlue = Color(0xFF4A90E2);
  static const Color deepBlue = Color(0xFF0047AB);
  static const Color cyan = Color(0xFF00E5FF);

  // ── Token Colors ──
  static const Color redToken = Color(0xFFE74C3C);
  static const Color greenToken = Color(0xFF2ECC71);
  static const Color yellowToken = Color(0xFFF39C12);
  static const Color blueToken = Color(0xFF3498DB);

  // ── Text ──
  static const Color textLight = Color(0xFFECF0F1);
  static const Color textMedium = Color(0xFF95A5A6);
  static const Color textDark = Color(0xFF2C3E50);

  // ── Utility ──
  static const Color gold = Color(0xFFFFD700);
  static const Color shadow = Color(0x4D000000);

  // ── Mint Green (Splash / Accents) ──
  static const Color mintGreen = Color(0xFF4AEABC);
  static const Color mintGreenLight = Color(0xFF7FFFDA);

  // ── Purple (Premium accents) ──
  static const Color purple = Color(0xFF7C4DFF);
  static const Color purpleLight = Color(0xFFB388FF);
  static const Color purpleDark = Color(0xFF4A148C);

  /// Returns the token color for a given player index (0–3).
  static Color tokenColor(int playerIndex) {
    switch (playerIndex) {
      case 0:
        return redToken;
      case 1:
        return greenToken;
      case 2:
        return yellowToken;
      case 3:
        return blueToken;
      default:
        return textMedium;
    }
  }
}
