import 'package:flutter/material.dart';

abstract class AppColors {
  /// Dark warm "ink" used on paper notes and light walls.
  static const ink = Color(0xFF3B372F);

  /// Warm chalk white used for text written directly on dark walls.
  static const chalk = Color(0xFFFDFBF3);

  static const deleteIcon = Color(0xFFC62828);
  static const pin = Color(0xFFD32F2F);
  static const paper = Color(0xFFFFF9E6);

  /// Pastel sticky-note paper colors.
  static const notePapers = [
    Color(0xFFFFF59D), // yellow
    Color(0xFFF8BBD0), // pink
    Color(0xFFB2DFDB), // mint
    Color(0xFFB3E5FC), // blue
    Color(0xFFFFE0B2), // orange
    Color(0xFFE1BEE7), // lilac
  ];
}

int stableHash(String s) =>
    s.codeUnits.fold(0, (acc, c) => (acc * 31 + c) & 0x7fffffff);

/// A note's paper color: the explicit [colorIndex] if set, else one derived
/// deterministically from the [guid] so it stays stable across runs.
Color noteColor(int? colorIndex, String guid) {
  final i = colorIndex ?? (stableHash(guid) % AppColors.notePapers.length);
  return AppColors.notePapers[i % AppColors.notePapers.length];
}

/// A wall the notes are stuck on: a seamless CC0 texture (ambientCG) plus a
/// scrim overlay tuned so text keeps enough contrast against the texture.
class WallStyle {
  const WallStyle({
    required this.id,
    required this.asset,
    required this.overlay,
    required this.dark,
  });

  /// Stable identifier, also used to pick the localized display name.
  final String id;
  final String asset;

  /// Painted over the texture: darkens/quiets it so writing stays readable.
  final Color overlay;

  /// true → chalk-white writing on the wall; false → dark ink.
  final bool dark;

  Color get wallText => dark ? AppColors.chalk : AppColors.ink;

  Color get wallTextFaded =>
      dark ? const Color(0xCCFDFBF3) : const Color(0xB33B372F);

  /// Soft shadow gives the "chalk/marker on wall" depth on dark walls.
  List<Shadow> get wallTextShadows => dark
      ? const [
          Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1))
        ]
      : const [];

  Color get dropdownSurface =>
      dark ? const Color(0xFF33322C) : const Color(0xFFF4F1E8);
}

const walls = [
  WallStyle(
    id: 'cork',
    asset: 'assets/images/wall_cork.jpg',
    overlay: Color(0x4D1F1008),
    dark: true,
  ),
  WallStyle(
    id: 'chalk_green',
    asset: 'assets/images/wall_concrete.jpg',
    overlay: Color(0xDE24342B),
    dark: true,
  ),
  WallStyle(
    id: 'chalk_black',
    asset: 'assets/images/wall_concrete.jpg',
    overlay: Color(0xE8161614),
    dark: true,
  ),
  WallStyle(
    id: 'plaster',
    asset: 'assets/images/wall_plaster.jpg',
    overlay: Color(0x0DFFFFFF),
    dark: false,
  ),
  WallStyle(
    id: 'brick',
    asset: 'assets/images/wall_brick.jpg',
    overlay: Color(0x66261410),
    dark: true,
  ),
  WallStyle(
    id: 'wood',
    asset: 'assets/images/wall_wood.jpg',
    overlay: Color(0x1A3B2F1E),
    dark: false,
  ),
];

/// A user-selectable font for notes and UI. All families bundled here include
/// the Vietnamese subset.
class FontChoice {
  const FontChoice({
    required this.id,
    required this.family,
    required this.label,
    this.scale = 1.0,
  });

  final String id;
  final String family;

  /// Proper name — not localized.
  final String label;

  /// Script faces with a small x-height get a size boost so all fonts read
  /// at a similar optical size.
  final double scale;
}

const fontChoices = [
  FontChoice(id: 'patrick', family: 'PatrickHand', label: 'Patrick Hand'),
  FontChoice(id: 'itim', family: 'Itim', label: 'Itim'),
  FontChoice(
    id: 'dancing',
    family: 'DancingScript',
    label: 'Dancing Script',
    scale: 1.15,
  ),
  FontChoice(
    id: 'bevietnam',
    family: 'BeVietnamPro',
    label: 'Be Vietnam Pro',
    scale: 0.9,
  ),
];

FontChoice fontChoiceById(String id) => fontChoices.firstWhere(
      (f) => f.id == id,
      orElse: () => fontChoices.first,
    );

/// Exposes the selected font's optical scale to widgets that set explicit
/// font sizes (note text).
class NoteTextScale extends ThemeExtension<NoteTextScale> {
  const NoteTextScale(this.scale);

  final double scale;

  @override
  NoteTextScale copyWith({double? scale}) => NoteTextScale(scale ?? this.scale);

  @override
  NoteTextScale lerp(ThemeExtension<NoteTextScale>? other, double t) => this;
}

ThemeData buildAppTheme(FontChoice font) {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: font.family,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8D6E63)),
  );

  return base.copyWith(
    extensions: [NoteTextScale(font.scale)],
    // Dialogs look like a sheet of note paper.
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: AppColors.paper,
      titleTextStyle: TextStyle(
        fontFamily: font.family,
        fontSize: 24 * font.scale,
        color: AppColors.ink,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF33322C),
      contentTextStyle: TextStyle(
        fontFamily: font.family,
        fontSize: 16 * font.scale,
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
