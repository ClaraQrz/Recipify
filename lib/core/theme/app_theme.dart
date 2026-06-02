import 'package:flutter/material.dart';

class AppTheme {
  // Paleta principal
  static const Color primary     = Color(0xFFC92C39); // vermelho escuro
  static const Color secondary   = Color(0xFFFFC15E); // amarelo dourado
  static const Color background  = Color(0xFFFFC15E); // fundo amarelo
  static const Color surface     = Color(0xFFF6DFBA); // creme dos cards
  static const Color cardBg      = Color(0xFFF5EDE0); // branco quente
  static const Color textDark    = Color(0xFF000100);
  static const Color textLight   = Color(0xFFFFFFFF);
  static const Color textGray    = Color(0xFF666666);
  static const Color warning     = Color(0xFFA30021); // vermelho alerta
  static const Color success     = Color(0xFF27AE60);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      background: background,
      surface: surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFF0A500),
      selectedItemColor: primary,
      unselectedItemColor: textDark,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textGray),
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: textLight,
    ),
  );
}