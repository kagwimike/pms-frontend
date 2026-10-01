import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color navy = Color(0xFF14233B);
  static const Color teal = Color(0xFF0F766E);
  static const Color brass = Color(0xFFE8A317);
  static const Color bgGreyGreen = Color(0xFFF2F5F4);
  static const Color mutedText = Color(0xFF5B6B7F);
  static const Color border = Color(0xFFD9E1E3);
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color white = Colors.white;

  static ThemeData get theme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bgGreyGreen,
      primaryColor: navy,
      colorScheme: base.colorScheme.copyWith(
        primary: navy,
        secondary: teal,
        tertiary: brass,
        background: bgGreyGreen,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          color: navy,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.bricolageGrotesque(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: navy,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: navy,
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: navy,
        ),
        bodyLarge: const TextStyle(
          fontSize: 18,
          color: mutedText,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 16,
          color: mutedText,
          height: 1.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
