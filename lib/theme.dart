import 'package:flutter/material.dart';

import 'util/stable_hash.dart';

export 'util/stable_hash.dart';

/// The palette: warm ink on paper, one sunny accent, a red pin.
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

  /// The white border of a photo print pinned on the wall.
  static const printPaper = Color(0xFFFCFAF4);

  /// Translucent dark chrome floated over the wall (zoom reset, handles).
  static const overlayDark = Color(0xCC33322C);

  /// Laid over artwork (a sketch, a photo) with the lights off: the same
  /// warm shadow [nightPaper] blends in, at the same strength (0.38 → 0x61),
  /// so a picture dims exactly as much as the paper next to it.
  static const nightShade = Color(0x617A6A4A);

  /// Yarn a thread can be tied with, classic red first (ARGB ints, since
  /// they are stored on the link).
  static const yarns = [
    0xFFC62828, // red
    0xFFEF6C00, // orange
    0xFFF9A825, // gold
    0xFF2E7D32, // green
    0xFF1565C0, // blue
    0xFF6A1B9A, // purple
    0xFF3B372F, // ink
  ];

  /// Marker colours for drawing straight on the wall: ink first, chalk last
  /// (for dark walls).
  static const markers = [
    0xFF3B372F, // ink
    0xFFD32F2F, // red
    0xFF1E63C6, // blue
    0xFF2E7D32, // green
    0xFFFDFBF3, // chalk
  ];

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

/// Corner radii: paper is barely rounded; controls and sheets more so.
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

/// The warm shadow tone paper takes on with the lights off.
const _nightTone = Color(0xFF7A6A4A);

/// Paper under a dimmed lamp: the pastel pulled toward a warm shadow tone.
Color nightPaper(Color day) => Color.lerp(day, _nightTone, 0.38)!;

/// [noteColor] as it should look right now — dimmed when the lights are off.
Color paperColorOf(BuildContext context, int? colorIndex, String guid) {
  final day = noteColor(colorIndex, guid);
  return isNight(context) ? nightPaper(day) : day;
}

/// The border colour of a photo print, dimmed with the lights off like the
/// note paper is.
Color printColorOf(BuildContext context) =>
    isNight(context) ? nightPaper(AppColors.printPaper) : AppColors.printPaper;

/// Whether the current theme is the "lights off" one.
bool isNight(BuildContext context) =>
    Theme.of(context).extension<NightMood>()?.night ?? false;

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
    this.imageFile,
  });

  /// A wall made of the user's own photo (an absolute file path). A dark
  /// photo gets a smoky scrim and chalk writing; a light one a milky scrim
  /// and ink — either way the picture stays visible but never fights text.
  factory WallStyle.photo(String path, {required bool dark}) => WallStyle(
    id: 'photo',
    asset: '',
    overlay: dark ? const Color(0x6B000000) : const Color(0x73FFFFFF),
    dark: dark,
    imageFile: path,
  );

  /// Stable identifier, also used to pick the localized display name.
  final String id;
  final String asset;

  /// Painted over the texture: darkens/quiets it so writing stays readable.
  final Color overlay;

  /// true → chalk-white writing on the wall; false → dark ink.
  final bool dark;

  /// Set for [WallStyle.photo] walls; null for the bundled textures.
  final String? imageFile;

  bool get isPhoto => imageFile != null;

  /// The same wall with the lights off: whatever the texture, text turns to
  /// chalk because the room is dark.
  WallStyle get atNight => WallStyle(
    id: id,
    asset: asset,
    overlay: overlay,
    dark: true,
    imageFile: imageFile,
  );

  Color get wallText => dark ? AppColors.chalk : AppColors.ink;

  Color get wallTextFaded =>
      dark ? const Color(0xCCFDFBF3) : const Color(0xB33B372F);

  /// Soft shadow gives the "chalk/marker on wall" depth on dark walls.
  List<Shadow> get wallTextShadows => dark
      ? const [
          Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
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
  // New walls are appended, never inserted: boards persist the wall by index.
  WallStyle(
    id: 'kraft',
    asset: 'assets/images/wall_kraft.jpg',
    overlay: Color(0x14FFFFFF),
    dark: false,
  ),
  WallStyle(
    id: 'marble',
    asset: 'assets/images/wall_marble.jpg',
    overlay: Color(0x1AFFFFFF),
    dark: false,
  ),
  WallStyle(
    id: 'terrazzo',
    asset: 'assets/images/wall_terrazzo.jpg',
    overlay: Color(0x33FFFFFF),
    dark: false,
  ),
  WallStyle(
    id: 'denim',
    asset: 'assets/images/wall_denim.jpg',
    overlay: Color(0x4D101C33),
    dark: true,
  ),
  WallStyle(
    id: 'felt',
    asset: 'assets/images/wall_felt.jpg',
    overlay: Color(0x33062A28),
    dark: true,
  ),
  WallStyle(
    id: 'linen',
    asset: 'assets/images/wall_linen.jpg',
    overlay: Color(0x40151412),
    dark: true,
  ),
];

/// The bundled wall with the given [WallStyle.id], or the first one.
WallStyle wallById(String id) =>
    walls.firstWhere((w) => w.id == id, orElse: () => walls.first);

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
  // Neat, rounded schoolbook handwriting.
  FontChoice(id: 'mali', family: 'Mali', label: 'Mali'),
  // Bold marker strokes.
  FontChoice(
    id: 'sriracha',
    family: 'Sriracha',
    label: 'Sriracha',
    scale: 0.95,
  ),
  // Quick, scratchy ballpoint notes.
  FontChoice(id: 'mynerve', family: 'Mynerve', label: 'Mynerve', scale: 1.05),
  // Bubbly, playful lettering.
  FontChoice(
    id: 'fuzzy',
    family: 'FuzzyBubbles',
    label: 'Fuzzy Bubbles',
    scale: 0.95,
  ),
  // Tall condensed capitals, poster style — needs a big boost to read.
  FontChoice(id: 'amatic', family: 'AmaticSC', label: 'Amatic SC', scale: 1.35),
  // Elegant upright script.
  FontChoice(id: 'charm', family: 'Charm', label: 'Charm', scale: 1.1),
  // Typewriter.
  FontChoice(
    id: 'plexmono',
    family: 'IBMPlexMono',
    label: 'Plex Mono',
    scale: 0.85,
  ),
];

/// The font with the given [FontChoice.id], or the default one.
FontChoice fontChoiceById(String id) =>
    fontChoices.firstWhere((f) => f.id == id, orElse: () => fontChoices.first);

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

/// Whether the room lights are off — the wall darkens and paper dims. Read
/// through [isNight]; set by [buildAppTheme].
class NightMood extends ThemeExtension<NightMood> {
  const NightMood(this.night);

  final bool night;

  @override
  NightMood copyWith({bool? night}) => NightMood(night ?? this.night);

  @override
  NightMood lerp(ThemeExtension<NightMood>? other, double t) => this;
}

/// The app theme: everything Material draws is "ink on paper", matching the
/// notes themselves. [font] is the user's chosen face; [night] dims every
/// paper surface to the lamp-lit tone the notes take when the lights are off.
ThemeData buildAppTheme(FontChoice font, {bool night = false}) {
  // At night every sheet of paper the UI is made of — dialogs, menus, bottom
  // sheets — dims to the same lamp-lit tone as the notes.
  final paper = night ? const Color(0xFFE9DFC6) : AppColors.paper;

  // Everything Material draws by default (radios, chips, sliders, buttons)
  // uses the same ink-on-paper palette as the notes, so no stock purple or
  // brown ever shows through.
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.ink,
    primary: AppColors.ink,
    onPrimary: AppColors.chalk,
    secondary: AppColors.accent,
    onSecondary: AppColors.ink,
    surface: paper,
    onSurface: AppColors.ink,
    error: AppColors.deleteIcon,
  );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: font.family,
    colorScheme: scheme,
  );
  const sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
  );
  const controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.control)),
  );
  final dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadii.control),
  );

  /// Resolves to [selected] when the control is on, else [rest].
  WidgetStateProperty<Color?> onOff(Color selected, Color? rest) =>
      WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? selected : rest,
      );

  /// [onOff] for the picker slots typed as a plain [Color].
  Color stateColor(Color selected, Color rest) => WidgetStateColor.resolveWith(
    (s) => s.contains(WidgetState.selected) ? selected : rest,
  );

  return base.copyWith(
    extensions: [NoteTextScale(font.scale), NightMood(night)],
    splashFactory: InkSparkle.splashFactory,
    iconTheme: const IconThemeData(color: AppColors.ink),
    dividerTheme: const DividerThemeData(color: AppColors.inkHint, space: 1),
    // Dialogs look like a sheet of note paper.
    dialogTheme: base.dialogTheme.copyWith(
      backgroundColor: paper,
      shape: dialogShape,
      titleTextStyle: TextStyle(
        fontFamily: font.family,
        fontSize: 24 * font.scale,
        color: AppColors.ink,
      ),
      contentTextStyle: TextStyle(
        fontFamily: font.family,
        fontSize: 16 * font.scale,
        height: 1.35,
        color: AppColors.ink,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: paper,
      shape: sheetShape,
      showDragHandle: true,
      dragHandleColor: AppColors.inkHint,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: paper,
      shape: controlShape,
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
      // A chip label does not inherit the ambient text style, so the font
      // has to be spelled out here or the chips fall back to the system one.
      labelStyle: TextStyle(
        fontFamily: font.family,
        fontSize: 15 * font.scale,
        color: AppColors.ink,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 18),
      checkmarkColor: AppColors.ink,
      shape: controlShape,
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
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.overlayDark,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: TextStyle(
        fontFamily: font.family,
        fontSize: 14 * font.scale,
        color: AppColors.chalk,
      ),
    ),
    // Text fields: a pencil line under the text rather than a boxed input.
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: AppColors.inkHint),
      labelStyle: TextStyle(color: AppColors.inkSoft),
      floatingLabelStyle: TextStyle(color: AppColors.ink),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.inkHint),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.ink, width: 1.6),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.deleteIcon),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.deleteIcon, width: 1.6),
      ),
      errorStyle: TextStyle(color: AppColors.deleteIcon),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.ink,
      selectionColor: AppColors.accent.withValues(alpha: 0.45),
      selectionHandleColor: AppColors.ink,
    ),
    // Toggles: an ink switch/box with a chalk mark, nothing tinted.
    switchTheme: SwitchThemeData(
      thumbColor: onOff(AppColors.chalk, AppColors.inkSoft),
      trackColor: onOff(AppColors.ink, Colors.transparent),
      trackOutlineColor: onOff(AppColors.ink, AppColors.inkSoft),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: onOff(AppColors.ink, Colors.transparent),
      checkColor: const WidgetStatePropertyAll(AppColors.chalk),
      side: const BorderSide(color: AppColors.inkSoft, width: 1.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: onOff(AppColors.ink, AppColors.inkSoft),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.ink,
      inactiveTrackColor: AppColors.inkHint,
      thumbColor: AppColors.ink,
      overlayColor: Color(0x1F3B372F),
    ),
    // Buttons: ink text; the one filled button is solid ink with chalk text.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        shape: controlShape,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.chalk,
        shape: controlShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.inkSoft),
        shape: controlShape,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: paper,
        foregroundColor: AppColors.ink,
        shape: controlShape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppColors.ink),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: AppColors.ink,
        selectedForegroundColor: AppColors.ink,
        selectedBackgroundColor: AppColors.ink.withValues(alpha: 0.16),
        side: const BorderSide(color: AppColors.inkHint),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.ink,
      linearTrackColor: AppColors.inkHint,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(paper),
        shape: const WidgetStatePropertyAll(controlShape),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(paper),
        shape: const WidgetStatePropertyAll(controlShape),
      ),
    ),
    // Reminder pickers: the same paper sheet with ink digits and a sunny
    // accent only on the selected day/hour.
    datePickerTheme: DatePickerThemeData(
      backgroundColor: paper,
      shape: dialogShape,
      headerForegroundColor: AppColors.ink,
      dayForegroundColor: onOff(AppColors.chalk, AppColors.ink),
      dayBackgroundColor: onOff(AppColors.ink, Colors.transparent),
      todayForegroundColor: onOff(AppColors.chalk, AppColors.ink),
      todayBackgroundColor: onOff(AppColors.ink, Colors.transparent),
      todayBorder: const BorderSide(color: AppColors.ink),
      yearForegroundColor: onOff(AppColors.chalk, AppColors.ink),
      yearBackgroundColor: onOff(AppColors.ink, Colors.transparent),
      dividerColor: AppColors.inkHint,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: paper,
      shape: dialogShape,
      dialBackgroundColor: AppColors.ink.withValues(alpha: 0.08),
      dialHandColor: AppColors.ink,
      dialTextColor: stateColor(AppColors.chalk, AppColors.ink),
      hourMinuteColor: stateColor(
        AppColors.accent,
        AppColors.ink.withValues(alpha: 0.08),
      ),
      hourMinuteTextColor: AppColors.ink,
      dayPeriodColor: stateColor(AppColors.accent, Colors.transparent),
      dayPeriodTextColor: AppColors.ink,
      dayPeriodBorderSide: const BorderSide(color: AppColors.inkSoft),
      entryModeIconColor: AppColors.ink,
      helpTextStyle: TextStyle(
        fontFamily: font.family,
        fontSize: 14 * font.scale,
        color: AppColors.inkSoft,
      ),
    ),
  );
}
