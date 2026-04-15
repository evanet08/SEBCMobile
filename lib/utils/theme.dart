import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SEBC Design System — Couleurs, typographies, thème
class SEBCColors {
  static const Color primary = Color(0xFF1A3A5C);
  static const Color primaryLight = Color(0xFF2C5F8A);
  static const Color primaryDark = Color(0xFF0F2440);
  static const Color accent = Color(0xFFC8102E);
  static const Color teal = Color(0xFF0D9488);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // Surfaces — Telegram sky-blue
  static const Color background = Color(0xFFD7E9F7);
  static const Color backgroundDark = Color(0xFFC4DCF0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F6FB);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF7C8FA3);

  // Chat — Telegram
  static const Color chatBg = Color(0xFFC4DCF0);
  static const Color chatSent = Color(0xFFEFFFDE);
  static const Color chatRecv = Color(0xFFFFFFFF);

  // App background gradient
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFFD7E9F7), Color(0xFFC4DCF0), Color(0xFFD0E4F4)],
  );

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFE83350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Avatar palette
  static const List<Color> avatarColors = [
    Color(0xFF1A3A5C), Color(0xFF0EA5E9), Color(0xFF059669),
    Color(0xFFD97706), Color(0xFFEC4899), Color(0xFF7C3AED),
    Color(0xFFEF4444), Color(0xFF14B8A6), Color(0xFFF97316),
    Color(0xFF06B6D4),
  ];
}

class SEBCTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SEBCColors.primary,
        primary: SEBCColors.primary,
        secondary: SEBCColors.accent,
        surface: SEBCColors.surface,
        error: SEBCColors.error,
      ),
      scaffoldBackgroundColor: SEBCColors.background,
      canvasColor: SEBCColors.background,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: SEBCColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: SEBCColors.cardBg,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SEBCColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SEBCColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SEBCColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: SEBCColors.textTertiary, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: SEBCColors.primary,
        unselectedItemColor: SEBCColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
