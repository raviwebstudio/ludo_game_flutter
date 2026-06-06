import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Typography tokens for Ludo Elite.
///
/// All styles use Poppins via Google Fonts.
class LudoTextStyles {
  LudoTextStyles._();

  // ── Display ──
  static TextStyle get displayLarge => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: LudoColors.textLight,
        letterSpacing: 0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: LudoColors.textLight,
      );

  // ── Headlines ──
  static TextStyle get headlineSmall => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: LudoColors.textLight,
      );

  static TextStyle get headlineXS => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: LudoColors.textLight,
      );

  // ── Body ──
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: LudoColors.textLight,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: LudoColors.textMedium,
      );

  // ── Labels / Captions ──
  static TextStyle get labelSmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: LudoColors.textMedium,
      );

  static TextStyle get labelBold => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: LudoColors.textLight,
      );

  // ── Special ──
  static TextStyle get gameTitle => GoogleFonts.poppins(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: LudoColors.textLight,
        letterSpacing: 4,
      );
}
