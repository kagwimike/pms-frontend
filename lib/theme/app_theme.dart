import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // New Brand System
  static const Color navy = Color(0xFF10231D); // Dark (used for headings/text)
  static const Color teal = Color(0xFF0F6B4F); // Primary (deep emerald green)
  static const Color brass = Color(0xFFE8A317);
  static const Color bgGreyGreen = Color(0xFFF7F9F8); // Very light neutral background
  static const Color mutedText = Color(0xFF6B7280); // Neutral gray tone
  static const Color border = Color(0xFFE5E7EB);
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color white = Colors.white;
  
  // Dark mode specifics
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkMutedText = Color(0xFFA1A1AA);
  static const Color darkBorder = Color(0xFF27272A);

  static ThemeData get theme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bgGreyGreen,
      primaryColor: navy,
      colorScheme: base.colorScheme.copyWith(
        primary: navy,
        secondary: teal,
        tertiary: brass,
        surface: bgGreyGreen,
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
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
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

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      primaryColor: teal,
      colorScheme: base.colorScheme.copyWith(
        primary: teal,
        secondary: brass,
        tertiary: teal,
        surface: darkSurface,
        brightness: Brightness.dark,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 56, fontWeight: FontWeight.w700, color: white, height: 1.1,
        ),
        displayMedium: GoogleFonts.bricolageGrotesque(
          fontSize: 40, fontWeight: FontWeight.w700, color: white, height: 1.2,
        ),
        headlineLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 32, fontWeight: FontWeight.w600, color: white,
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          fontSize: 24, fontWeight: FontWeight.w600, color: white,
        ),
        bodyLarge: const TextStyle(fontSize: 18, color: darkMutedText, height: 1.5),
        bodyMedium: const TextStyle(fontSize: 16, color: darkMutedText, height: 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
