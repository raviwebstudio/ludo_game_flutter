import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

/// The Ludo Elite dark Material 3 theme.
class AppTheme {
  AppTheme._();

  static ThemeData get ludoTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: LudoColors.softBlue,
      scaffoldBackgroundColor: LudoColors.darkNavy,
      colorScheme: const ColorScheme.dark(
        primary: LudoColors.softBlue,
        secondary: LudoColors.brightBlue,
        surface: LudoColors.darkNavyLight,
        error: LudoColors.redToken,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: LudoColors.darkNavyDark,
        foregroundColor: LudoColors.textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: LudoColors.textLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LudoColors.softBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: LudoColors.textLight,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: LudoColors.textLight,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: LudoColors.textLight,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: LudoColors.textLight,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: LudoColors.textMedium,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: LudoColors.textMedium,
        ),
      ),
      cardTheme: CardThemeData(
        color: LudoColors.darkNavyLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
      ),
      dividerColor: LudoColors.textMedium.withValues(alpha: 0.2),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LudoColors.mintGreen;
          }
          return LudoColors.textMedium;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LudoColors.mintGreen.withValues(alpha: 0.3);
          }
          return LudoColors.darkNavyDark;
        }),
      ),
    );
  }
}
