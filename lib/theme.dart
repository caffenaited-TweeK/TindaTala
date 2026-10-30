import 'package:flutter/material.dart';

class TindaColors {
  static const cream = Color(0xFFFFF8E9);
  static const ivory = Color(0xFFFFFCF5);
  static const red = Color(0xFFC9432F);
  static const brown = Color(0xFF4A281B);
  static const yellow = Color(0xFFF4B83F);
  static const green = Color(0xFF397A4A);
  static const amber = Color(0xFFD98A16);
  static const error = Color(0xFFB8322A);
  static const blue = Color(0xFF397CA5);
  static const mutedBrown = Color(0xFF806653);
}

ThemeData buildTindaTheme() {
  const outline = TindaColors.brown;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: TindaColors.red,
    brightness: Brightness.light,
    primary: TindaColors.red,
    onPrimary: TindaColors.ivory,
    secondary: TindaColors.yellow,
    onSecondary: TindaColors.brown,
    surface: TindaColors.ivory,
    onSurface: TindaColors.brown,
    error: TindaColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: TindaColors.cream,
    fontFamily: 'Nunito',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: TindaColors.brown,
        fontSize: 26,
        fontWeight: FontWeight.w900,
        height: 1.15,
      ),
      titleLarge: TextStyle(
        color: TindaColors.brown,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: TindaColors.brown,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      bodyMedium: TextStyle(
        color: TindaColors.brown,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        color: TindaColors.mutedBrown,
        fontSize: 12,
        height: 1.35,
      ),
    ),
    cardTheme: CardThemeData(
      color: TindaColors.ivory,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: outline, width: 1.4),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TindaColors.ivory,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      hintStyle: const TextStyle(color: TindaColors.mutedBrown),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outline, width: 1.3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outline, width: 1.3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TindaColors.red, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TindaColors.red,
        foregroundColor: TindaColors.ivory,
        minimumSize: const Size(44, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: TindaColors.brown, width: 1.2),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TindaColors.brown,
        backgroundColor: TindaColors.ivory,
        minimumSize: const Size(44, 46),
        side: const BorderSide(color: TindaColors.brown, width: 1.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: TindaColors.ivory,
      indicatorColor: const Color(0xFFFCE6DC),
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? TindaColors.red
              : TindaColors.mutedBrown,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TindaColors.brown,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(color: TindaColors.ivory),
    ),
  );
}
