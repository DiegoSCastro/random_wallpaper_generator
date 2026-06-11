import 'package:flutter/material.dart';

/// Liquid-glass neutral theme.
///
/// - Translucent surfaces via [Colors.transparent] + system blur (BackdropFilter
///   applied per-screen, not at theme level — Material can't carry it).
/// - Very low contrast chrome: scrim 8% black on top of wallpaper.
/// - Wallpaper is the hero; the theme is the empty frame around it.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: isDark ? const Color(0xFF202428) : const Color(0xFFF0F2F4),
        brightness: brightness,
        surface: isDark
            ? Colors.black.withValues(alpha: 0.20)
            : Colors.white.withValues(alpha: 0.20),
        surfaceContainer: isDark
            ? Colors.black.withValues(alpha: 0.30)
            : Colors.white.withValues(alpha: 0.30),
        onSurface: isDark ? Colors.white : Colors.black,
        onSurfaceVariant: isDark ? Colors.white70 : Colors.black87,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
      textTheme: _textTheme(isDark),
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : Colors.black,
        size: 22,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.08),
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : Colors.black,
          side: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.18),
          ),
          shape: const StadiumBorder(),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: isDark ? Colors.white : Colors.black,
        unselectedItemColor: (isDark ? Colors.white : Colors.black)
            .withValues(alpha: 0.55),
        showUnselectedLabels: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? Colors.black.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.92),
        contentTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
      ),
    );
    return base;
  }

  static TextTheme _textTheme(bool isDark) {
    final color = isDark ? Colors.white : Colors.black;
    return TextTheme(
      displayLarge: TextStyle(color: color, fontWeight: FontWeight.w200),
      displayMedium: TextStyle(color: color, fontWeight: FontWeight.w300),
      headlineMedium: TextStyle(color: color, fontWeight: FontWeight.w400),
      titleLarge: TextStyle(color: color, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: color),
      bodyMedium: TextStyle(color: color.withValues(alpha: 0.85)),
      labelLarge: TextStyle(color: color, fontWeight: FontWeight.w500),
    );
  }
}
