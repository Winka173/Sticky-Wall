import 'package:flutter/material.dart';

import 'util/stable_hash.dart';

export 'util/stable_hash.dart';

abstract class AppColors {
  /// Dark warm "ink" used on paper notes and light walls.
  static const ink = Color(0xFF3B372F);

  /// Ink at reduced strength, for secondary text and hints on paper.
  static const inkSoft = Color(0x993B372F);
  static const inkHint = Color(0x593B372F);

  /// Warm chalk white used for text written directly on dark walls.
  static const chalk = Color(0xFFFDFBF3);

  /// Sunny accent for the primary action and small badges.
  static const accent = Color(0xFFFFCA28);

  static const link = Color(0xFF1A55A5);
  static const deleteIcon = Color(0xFFC62828);
  static const pin = Color(0xFFD32F2F);
  static const paper = Color(0xFFFFF9E6);

  /// Translucent dark chrome floated over the wall (zoom reset, handles).
  static const overlayDark = Color(0xCC33322C);

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

abstract class AppRadii {
  static const paper = 3.0;
  static const control = 8.0;
  static const sheet = 20.0;
}

/// A note's paper color: the explicit [colorIndex] if set, else one derived
/// deterministically from the [guid] so it stays stable across runs.
Color noteColor(int? colorIndex, String guid) {
  final i = colorIndex ?? (stableHash(guid) % AppColors.notePapers.length);
  return AppColors.notePapers[i % AppColors.notePapers.length];
}

/// The selected font's optical scale (see [FontChoice.scale]).
double noteFontScale(BuildContext context) =>
    Theme.of(context).extension<NoteTextScale>()?.scale ?? 1.0;

/// The one text style for note body text — used by both the editor and the
/// cards, so what you write is exactly what lands on the wall.
TextStyle noteBodyStyle(BuildContext context) => TextStyle(
      color: AppColors.ink,
      fontSize: 18 * noteFontScale(context),
      height: 1.4,
    );

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
  // Everything Material draws by default (radios, chips, sliders, buttons)
  // uses the same ink-on-paper palette as the notes, so no stock purple or
  // brown ever shows through.
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.ink,
    primary: AppColors.ink,
    onPrimary: AppColors.chalk,
    surface: AppColors.paper,
    onSurface: AppColors.ink,
  );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: font.family,
    colorScheme: scheme,
  );
  const sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
  );

  return base.copyWith(
    extensions: [NoteTextScale(font.scale)],
    splashFactory: InkSparkle.splashFactory,
    // Dialogs look like a sheet of note paper.
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: AppColors.paper,
      titleTextStyle: TextStyle(
        fontFamily: font.family,
        fontSize: 24 * font.scale,
        color: AppColors.ink,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.paper,
      shape: sheetShape,
      showDragHandle: true,
      dragHandleColor: AppColors.inkHint,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.paper,
      textStyle: TextStyle(
        fontFamily: font.family,
        fontSize: 16 * font.scale,
        color: AppColors.ink,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.ink,
      textColor: AppColors.ink,
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: AppColors.ink.withValues(alpha: 0.16),
      side: const BorderSide(color: AppColors.inkHint),
      labelStyle: const TextStyle(color: AppColors.ink),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF33322C),
      actionTextColor: AppColors.accent,
      contentTextStyle: TextStyle(
        fontFamily: font.family,
        fontSize: 16 * font.scale,
        color: AppColors.chalk,
      ),
    ),
  );
}
