import 'package:flutter/material.dart';

abstract class AppColors {
  /// Dark warm "ink" used on paper notes and light walls.
  static const ink = Color(0xFF3B372F);

  /// Warm chalk white used for text written directly on dark walls.
  static const chalk = Color(0xFFFDFBF3);

  static const deleteIcon = Color(0xFFC62828);
  static const pin = Color(0xFFD32F2F);

  /// Pastel sticky-note paper colors. A note picks one deterministically
  /// from its guid so the color is stable.
  static const notePapers = [
    Color(0xFFFFF59D), // yellow
    Color(0xFFF8BBD0), // pink
    Color(0xFFB2DFDB), // mint
    Color(0xFFB3E5FC), // blue
    Color(0xFFFFE0B2), // orange
    Color(0xFFE1BEE7), // lilac
  ];
}

/// A wall the notes are stuck on: a seamless CC0 texture (ambientCG) plus a
/// scrim overlay tuned so text keeps enough contrast against the texture.
class WallStyle {
  const WallStyle({
    required this.id,
    required this.label,
    required this.asset,
    required this.overlay,
    required this.dark,
  });

  final String id;
  final String label;
  final String asset;

  /// Painted over the texture: darkens/quiets it so writing stays readable.
  final Color overlay;

  /// true → chalk-white writing on the wall; false → dark ink.
  final bool dark;

  Color get wallText => dark ? AppColors.chalk : AppColors.ink;

  Color get wallTextFaded => dark ? const Color(0xCCFDFBF3) : const Color(0xB33B372F);

  /// Soft shadow gives the "chalk/marker on wall" depth on dark walls.
  List<Shadow> get wallTextShadows => dark
      ? const [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1))]
      : const [];

  Color get dropdownSurface =>
      dark ? const Color(0xFF33322C) : const Color(0xFFF4F1E8);
}

const walls = [
  WallStyle(
    id: 'cork',
    label: 'Cork board',
    asset: 'assets/images/wall_cork.jpg',
    overlay: Color(0x4D1F1008),
    dark: true,
  ),
  WallStyle(
    id: 'chalkboard',
    label: 'Chalkboard',
    asset: 'assets/images/wall_concrete.jpg',
    overlay: Color(0xDE24342B),
    dark: true,
  ),
  WallStyle(
    id: 'plaster',
    label: 'Painted wall',
    asset: 'assets/images/wall_plaster.jpg',
    overlay: Color(0x0DFFFFFF),
    dark: false,
  ),
];

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'PatrickHand',
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8D6E63)),
  );

  return base.copyWith(
    // Dialogs look like a sheet of note paper.
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: const Color(0xFFFFF9E6),
      titleTextStyle: const TextStyle(
        fontFamily: 'PatrickHand',
        fontSize: 24,
        color: AppColors.ink,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xFF33322C),
      contentTextStyle: TextStyle(
        fontFamily: 'PatrickHand',
        fontSize: 16,
        color: AppColors.chalk,
      ),
    ),
  );
}

/// Local theme override so toolbar controls (labels, underlines, icons)
/// match the writing color of the current wall.
ThemeData wallControlsTheme(BuildContext context, WallStyle wall) {
  final theme = Theme.of(context);
  final text = wall.wallText;
  final faded = wall.wallTextFaded;

  return theme.copyWith(
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: faded),
      floatingLabelStyle: TextStyle(color: text),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: faded),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: text),
      ),
    ),
    iconTheme: IconThemeData(color: text),
    textSelectionTheme: TextSelectionThemeData(cursorColor: text),
  );
}
