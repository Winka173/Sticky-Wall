import 'package:flutter/material.dart';

/// Palette lifted from the original Mia Note web app.
abstract class AppColors {
  static const gradientStart = Color(0xFF304352);
  static const gradientEnd = Color(0xFF757371);
  static const normalNote = Color(0xFFFFC0CB); // CSS `pink`
  static const link = Color(0xFFFFDAB9); // CSS `peachpuff`
  static const linkVisited = Color(0xFFFFC0CB);
  static const deleteIcon = Color(0xDEFF5555);
  static const cardBackground = Color(0x41000000);
}

const appGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [AppColors.gradientStart, AppColors.gradientEnd],
);

ThemeData buildAppTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.gradientStart,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    useMaterial3: true,
  );

  return base.copyWith(
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.white70),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white54),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}
