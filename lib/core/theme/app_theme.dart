import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors from Stitch Design
  static const Color primary = Color(0xFFFFB4A8); // Peach/Coral primary
  static const Color onPrimary = Color(0xFF690000); 
  static const Color secondary = Color(0xFFAFC6FF);
  static const Color onSecondary = Color(0xFF002D6C);
  
  static const Color background = Color(0xFF121212); // surface-main
  static const Color surface = Color(0xFF001621); // surface / background
  static const Color surfaceContainer = Color(0xFF1E1E1E); 
  static const Color surfaceContainerLow = Color(0xFF001E2C);
  static const Color surfaceContainerHigh = Color(0xFF042E3F);
  static const Color surfaceContainerHighest = Color(0xFF13384B);
  
  // Backwards compatibility aliases
  static const Color surfaceLow = surfaceContainerLow;
  static const Color surfaceVariant = surfaceContainerHighest;
  static const Color surfaceDim = Color(0xFF001621);
  static const Color surfaceHigh = surfaceContainerHigh;

  static const Color onSurface = Color(0xFFF8F9FA); 
  static const Color onSurfaceVariant = Color(0xFFC4C7C5);
  static const Color outline = Color(0xFFAB8983);
  static const Color outlineVariant = Color(0xFF5C403C);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: onSecondary,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        surfaceContainerHighest: surfaceContainerHighest,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.beVietnamPro(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.beVietnamPro(
          fontSize: 44,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineLarge: GoogleFonts.beVietnamPro(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.beVietnamPro(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.beVietnamPro(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.beVietnamPro(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.beVietnamPro(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: onSurface,
          height: 1.44,
        ),
        bodyMedium: GoogleFonts.beVietnamPro(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: onSurface,
          letterSpacing: 0.1,
        ),
        labelSmall: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.transparent, width: 0),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: primary,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
