import 'package:flutter/material.dart';

class AppTheme {

  static const Color primary   = Color(0xFFC92C39);
  static const Color secondary = Color(0xFFFFC15E);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color warning   = Color(0xFFA30021);
  static const Color success   = Color(0xFF27AE60);

  static const Color _lBackground = Color(0xFFFFC15E);
  static const Color _lSurface    = Color(0xFFF6DFBA);
  static const Color _lCardBg     = Color(0xFFF5EDE0);
  static const Color _lTextDark   = Color(0xFF000100);
  static const Color _lTextGray   = Color(0xFF666666);

  static const Color _dBackground = Color(0xFF1E1410);
  static const Color _dSurface    = Color.fromARGB(255, 73, 53, 45);
  static const Color _dCardBg     = Color.fromARGB(255, 68, 44, 36);
  static const Color _dTextDark   = Color(0xFFF2E4D8);
  static const Color _dTextGray   = Color(0xFFAA8F80);

 
  static const Color background = _lBackground;
  static const Color surface    = _lSurface;
  static const Color cardBg     = _lCardBg;
  static const Color textDark   = _lTextDark;
  static const Color textGray   = _lGray;
  static const Color _lGray     = _lTextGray;

  static const double defaultRadius = 16;
  static const EdgeInsets pagePadding = EdgeInsets.all(16);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? _dSurface : _lSurface;

  static Color cardBgOf(BuildContext context) =>
      isDark(context) ? _dCardBg : _lCardBg;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? _dBackground : _lBackground;

  static Color textDarkOf(BuildContext context) =>
      isDark(context) ? _dTextDark : _lTextDark;

  static Color textGrayOf(BuildContext context) =>
      isDark(context) ? _dTextGray : _lTextGray;

  static ThemeData get light => _build(
    brightness: Brightness.light,
    scaffoldBg: _lCardBg,
    surfaceColor: _lSurface,
    appBarBg: _lBackground,
    cardColor: _lCardBg,
    inputFill: _lSurface,
    textPrimary: _lTextDark,
    textSecondary: _lTextGray,
    navBg: secondary,
    navUnselected: _lTextDark,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scaffoldBg: _dCardBg,
    surfaceColor: _dSurface,
    appBarBg: _dBackground,
    cardColor: _dCardBg,
    inputFill: _dSurface,
    textPrimary: _dTextDark,
    textSecondary: _dTextGray,
    navBg: _dBackground,
    navUnselected: _dTextGray,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surfaceColor,
    required Color appBarBg,
    required Color cardColor,
    required Color inputFill,
    required Color textPrimary,
    required Color textSecondary,
    required Color navBg,
    required Color navUnselected,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        surface: surfaceColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge:    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primary),
        titleMedium:   TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge:     TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium:    TextStyle(fontSize: 14, color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBg,
        selectedItemColor: primary,
        unselectedItemColor: navUnselected,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: textLight,
      ),
    );
  }
}