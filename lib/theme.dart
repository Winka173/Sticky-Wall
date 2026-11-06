import 'package:flutter/material.dart';

import 'util/seasons.dart';
import 'util/stable_hash.dart';

export 'util/seasons.dart';
export 'util/stable_hash.dart';

/// The palette: warm ink on paper, one sunny accent, a red pin.
abstract class AppColors {
  /// Dark warm "ink" used on paper notes and light walls.
  static const ink = Color(0xFF3B372F);

  /// Ink at reduced strength, for secondary text and hints on paper.
  /// Secondary text stays at 4.5:1 on every day paper (about 4:1 with the
  /// lights off); hints are lighter, but still read as words.
  static const inkSoft = Color(0xEB3B372F);
  static const inkHint = Color(0x993B372F);

  /// Warm chalk white used for text written directly on dark walls.
  static const chalk = Color(0xFFFDFBF3);

  /// Sunny accent for the primary action and small badges.
  static const accent = Color(0xFFFFCA28);

  /// Words and icons for Pro on light paper: the accent's deep amber, 5:1
  /// on [paper].
  static const proInk = Color(0xFF8A5300);

  /// Deep enough to keep 4.5:1 on the dimmed papers too.
  static const link = Color(0xFF123A73);
  static const deleteIcon = Color(0xFFC62828);

  /// Red for words on paper (overdue, errors): [deleteIcon] is too light to
  /// read at 4.5:1 on pink or lilac.
  static const warnText = Color(0xFF7A1414);
  static const pin = Color(0xFFD32F2F);
  static const paper = Color(0xFFFFF9E6);

  /// The white border of a photo print pinned on the wall.
  static const printPaper = Color(0xFFFCFAF4);

  /// Translucent dark chrome floated over the wall (zoom reset, handles).
  static const overlayDark = Color(0xCC33322C);
  static const outline = Color(0x333B372F);
  static const disabledInk = Color(0x803B372F);
  static const shadow = Color(0xFF302318);

  /// Laid over artwork (a sketch, a photo) with the lights off: the same
  /// warm shadow [nightPaper] blends in, at the same strength (0.30 → 0x4D),
  /// so a picture dims exactly as much as the paper next to it.
  static const nightShade = Color(0x4D7A6A4A);

  /// Yarn a thread can be tied with, classic red first (ARGB ints, since
  /// they are stored on the link). The first [freeYarns] come with the app.
  static const yarns = [
    0xFFC62828, // red
    0xFFEF6C00, // orange
    0xFFF9A825, // gold
    0xFF2E7D32, // green
    0xFF1565C0, // blue
    0xFF6A1B9A, // purple
    0xFF3B372F, // ink
    // Pro.
    0xFFD81B60, // pink
    0xFF00897B, // teal
    0xFF8D6E63, // brown
    0xFFF5F2EA, // white
  ];

  static const freeYarns = 7;

  /// Marker colours for drawing straight on the wall: ink first, then
  /// chalk for dark walls ([markerChalk]); strokes keep their ARGB, so Pro
  /// colours are appended after the first [freeMarkers].
  static const markers = [
    0xFF3B372F, // ink
    0xFFD32F2F, // red
    0xFF1E63C6, // blue
    0xFF2E7D32, // green
    markerChalk,
    // Pro.
    0xFFEF6C00, // orange
    0xFF8E24AA, // purple
    0xFFD81B60, // pink
    0xFF00897B, // teal
    0xFFFBC02D, // yellow
  ];

  static const markerChalk = 0xFFFDFBF3;
  static const freeMarkers = 5;

  /// Highlighter strokes are the marker colour at this opacity (0..255).
  static const highlighterAlpha = 0x66;

  /// Pastel sticky-note paper colors. The first [freePapers] come with the
  /// app; the rest are Sticky Wall Pro's. Notes store the index, so new
  /// papers are appended, never inserted.
  static const notePapers = [
    Color(0xFFFFF59D), // yellow
    Color(0xFFF8BBD0), // pink
    Color(0xFFB2DFDB), // mint
    Color(0xFFB3E5FC), // blue
    Color(0xFFFFE0B2), // orange
    Color(0xFFE1BEE7), // lilac
    // Pro — each still keeps ink at 5:1 with the lights off.
    Color(0xFFE6EE9C), // lime
    Color(0xFFFFCCBC), // coral
    Color(0xFFC5CAE9), // periwinkle
    Color(0xFFD6E2C3), // sage
    Color(0xFFE4D2B0), // kraft
    Color(0xFFFAFAF7), // white
  ];

  /// How many of [notePapers] are free; the rest need Pro.
  static const freePapers = 6;
}

/// Corner radii: paper is barely rounded; controls and sheets more so.
/// A rounded, softly filled search box with the magnifier centred on the
/// text line. Pair it with `textAlignVertical: TextAlignVertical.center`.
InputDecoration searchFieldDecoration(String hint) {
  const shape = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.control * 2)),
    borderSide: BorderSide(color: AppColors.inkHint),
  );
  return InputDecoration(
    hintText: hint,
    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.inkSoft),
    prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    isDense: true,
    contentPadding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
    filled: true,
    fillColor: AppColors.ink.withValues(alpha: 0.04),
    border: shape,
    enabledBorder: shape,
    focusedBorder: shape.copyWith(
      borderSide: const BorderSide(color: AppColors.ink, width: 1.6),
    ),
  );
}

abstract class AppRadii {
  static const paper = 3.0;
  static const control = 8.0;
  static const sheet = 20.0;
}

/// Presentation tokens only: never used as persisted theme or palette IDs.
abstract class AppSpace {
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
}

abstract class AppMetrics {
  static const target = 48.0;
  static const icon = 22.0;

  static Duration motion(BuildContext context, {int milliseconds = 180}) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : Duration(milliseconds: milliseconds);
}

abstract class AppElevation {
  static List<BoxShadow> paper({bool raised = false}) => [
    BoxShadow(
      color: AppColors.shadow.withValues(alpha: raised ? .34 : .23),
      blurRadius: raised ? 16 : 8,
      offset: Offset(raised ? 4 : 2, raised ? 10 : 4),
    ),
  ];
}

/// Outlined Material glyphs share one optical size. Filled variants are reserved
/// for active states; decorative emoji remain content rather than app controls.
abstract class AppIcons {
  static const note = Icons.sticky_note_2_outlined;
  static const checklist = Icons.checklist_rounded;
  static const photo = Icons.photo_outlined;
  static const link = Icons.link_rounded;
  static const voice = Icons.mic_none_rounded;
  static const drawing = Icons.brush_outlined;
  static const label = Icons.label_outline_rounded;
  static const sticker = Icons.emoji_emotions_outlined;
  static const memory = Icons.photo_library_outlined;
  static const pin = Icons.push_pin_outlined;
  static const positionLock = Icons.lock_outline_rounded;
  static const archive = Icons.inventory_2_outlined;
  static const delete = Icons.delete_outline_rounded;
  static const more = Icons.more_horiz_rounded;
}

abstract class AppType {
  static TextStyle heading(BuildContext context) => TextStyle(
    fontSize: 24 * noteFontScale(context),
    height: 1.25,
    color: AppColors.ink,
    fontWeight: FontWeight.w600,
  );

  static TextStyle control(BuildContext context) => const TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 15,
    height: 1.4,
    color: AppColors.ink,
    fontWeight: FontWeight.w500,
  );

  static TextStyle caption(BuildContext context) => const TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 12,
    height: 1.5,
    color: AppColors.inkSoft,
  );
}

/// A paper colour mixed by the user (Sticky Wall Pro) is stored in the same
/// `colorIndex` field as the palette's indices, as its ARGB value: anything
/// from here up is a colour, not an index. An older version reading one just
/// wraps it onto the palette.
const customPaperBase = 0x01000000;

/// [color] as a note stores it in `colorIndex` (always opaque).
int customPaper(Color color) => color.toARGB32() | 0xFF000000;

/// Whether [colorIndex] is a mixed colour rather than a palette index.
bool isCustomPaper(int? colorIndex) =>
    colorIndex != null && colorIndex >= customPaperBase;

/// A note's paper color: the explicit [colorIndex] if set (a palette index
/// or a mixed colour, see [customPaperBase]), else one derived
/// deterministically from the [guid] so it stays stable across runs — always
/// one of the free papers, so adding papers never recolours old notes.
Color noteColor(int? colorIndex, String guid) {
  if (isCustomPaper(colorIndex)) return Color(colorIndex!);
  final i = colorIndex ?? (stableHash(guid) % AppColors.freePapers);
  return AppColors.notePapers[i % AppColors.notePapers.length];
}

/// The warm shadow tone paper takes on with the lights off.
const _nightTone = Color(0xFF7A6A4A);

/// Paper under a dimmed lamp: the pastel pulled toward a warm shadow tone —
/// no further than ink still reads on it at 5:1.
Color nightPaper(Color day) => Color.lerp(day, _nightTone, 0.30)!;

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
    this.pro = false,
    this.season,
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

  /// Part of Sticky Wall Pro: shown to everyone, chosen only once bought.
  final bool pro;

  /// A seasonal pack's wall. It can be picked all year; around its
  /// occasion it is listed first.
  final Season? season;

  /// Whether its occasion is near (always true for a year-round wall).
  bool get inSeason => season == null || seasonOpen(season!);

  /// The same wall with the lights off: whatever the texture, text turns to
  /// chalk because the room is dark.
  WallStyle get atNight => WallStyle(
    id: id,
    asset: asset,
    overlay: overlay,
    dark: true,
    imageFile: imageFile,
    pro: pro,
    season: season,
  );

  Color get wallText => dark ? AppColors.chalk : AppColors.ink;

  /// Secondary words written on the wall: lighter than [wallText], but not
  /// so light that the texture swallows them.
  Color get wallTextFaded =>
      dark ? const Color(0xE6FDFBF3) : const Color(0xE63B372F);

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
    overlay: Color(0x26FFFFFF),
    dark: false,
  ),
  // New walls are appended, never inserted: boards persist the wall by index.
  WallStyle(
    id: 'kraft',
    asset: 'assets/images/wall_kraft.jpg',
    overlay: Color(0x2EFFFFFF),
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
  WallStyle(
    id: 'cardboard',
    asset: 'assets/images/wall_cardboard.jpg',
    overlay: Color(0x33FFFFFF),
    dark: false,
  ),
  WallStyle(
    id: 'cement',
    asset: 'assets/images/wall_cement.jpg',
    overlay: Color(0x1AFFFFFF),
    dark: false,
  ),
  WallStyle(
    id: 'cotton',
    asset: 'assets/images/wall_cotton.jpg',
    overlay: Color(0x0AFFFFFF),
    dark: false,
  ),
  WallStyle(
    id: 'paper',
    asset: 'assets/images/wall_paper.jpg',
    overlay: Color(0x00FFFFFF),
    dark: false,
  ),
  WallStyle(
    id: 'moss',
    asset: 'assets/images/wall_moss.jpg',
    overlay: Color(0x59182412),
    dark: true,
  ),
  WallStyle(
    id: 'leather',
    asset: 'assets/images/wall_leather.jpg',
    overlay: Color(0x40140606),
    dark: true,
  ),
  WallStyle(
    id: 'dark_marble',
    asset: 'assets/images/wall_dark_marble.jpg',
    overlay: Color(0x330A0A0A),
    dark: true,
  ),
  WallStyle(
    id: 'dark_wood',
    asset: 'assets/images/wall_dark_wood.jpg',
    overlay: Color(0x4D1E1208),
    dark: true,
  ),
  WallStyle(
    id: 'tiles',
    asset: 'assets/images/wall_tiles.jpg',
    // Half the squares are near-black, so chalk on a darkened floor reads
    // on every square; ink on the bright ones would vanish on the dark.
    overlay: Color(0x8C1C1714),
    dark: true,
  ),
  // Pro: the bundled textures tinted, so they cost no download size.
  WallStyle(
    id: 'chalk_navy',
    asset: 'assets/images/wall_concrete.jpg',
    overlay: Color(0xE0182640),
    dark: true,
    pro: true,
  ),
  WallStyle(
    id: 'chalk_wine',
    asset: 'assets/images/wall_concrete.jpg',
    overlay: Color(0xDE3A1622),
    dark: true,
    pro: true,
  ),
  WallStyle(
    id: 'blush',
    asset: 'assets/images/wall_plaster.jpg',
    overlay: Color(0x47F2A7A0),
    dark: false,
    pro: true,
  ),
  WallStyle(
    id: 'sage',
    asset: 'assets/images/wall_plaster.jpg',
    overlay: Color(0x4D9DB58C),
    dark: false,
    pro: true,
  ),
  WallStyle(
    id: 'sky',
    asset: 'assets/images/wall_cotton.jpg',
    overlay: Color(0x4D8DB8E0),
    dark: false,
    pro: true,
  ),
  // Pro seasonal packs: seamless patterns, kept low in contrast so the
  // writing on top stays readable.
  WallStyle(
    id: 'tet',
    asset: 'assets/images/wall_tet.jpg',
    overlay: Color(0x1A000000),
    dark: true,
    pro: true,
    season: Season.tet,
  ),
  WallStyle(
    id: 'tet_dao',
    asset: 'assets/images/wall_tet_dao.jpg',
    overlay: Color(0x1A000000),
    dark: true,
    pro: true,
    season: Season.tet,
  ),
  WallStyle(
    id: 'xmas',
    asset: 'assets/images/wall_xmas.jpg',
    overlay: Color(0x14000000),
    dark: true,
    pro: true,
    season: Season.christmas,
  ),
  WallStyle(
    id: 'moon',
    asset: 'assets/images/wall_moon.jpg',
    overlay: Color(0x14000000),
    dark: true,
    pro: true,
    season: Season.midAutumn,
  ),
  WallStyle(
    id: 'love',
    asset: 'assets/images/wall_love.jpg',
    overlay: Color(0x0FFFFFFF),
    dark: false,
    pro: true,
    season: Season.valentine,
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
    this.pro = false,
  });

  final String id;
  final String family;

  /// Proper name — not localized.
  final String label;

  /// Script faces with a small x-height get a size boost so all fonts read
  /// at a similar optical size.
  final double scale;

  /// Part of Sticky Wall Pro.
  final bool pro;
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
  // Pro — every one checked for the full Vietnamese set too.
  // Lively, slightly wobbly marker handwriting.
  FontChoice(
    id: 'shantell',
    family: 'ShantellSans',
    label: 'Shantell Sans',
    scale: 0.95,
    pro: true,
  ),
  // Chunky rounded poster lettering.
  FontChoice(
    id: 'coiny',
    family: 'Coiny',
    label: 'Coiny',
    scale: 0.9,
    pro: true,
  ),
  // Retro sign-painter script.
  FontChoice(
    id: 'lobster',
    family: 'Lobster',
    label: 'Lobster',
    scale: 0.9,
    pro: true,
  ),
  // Fast, slanted graffiti hand.
  FontChoice(
    id: 'sedgwick',
    family: 'SedgwickAve',
    label: 'Sedgwick Ave',
    scale: 0.8,
    pro: true,
  ),
  // A calm book serif.
  FontChoice(id: 'lora', family: 'Lora', label: 'Lora', scale: 0.95, pro: true),
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

/// How notes are held to the wall. The red push-pin comes with the app; the
/// others are Sticky Wall Pro's. Whatever the style, a note pinned to the top
/// shows it in gold.
enum PinStyle {
  classic,
  colorful,
  tack,
  washi,
  clip,
  magnet;

  bool get pro => this != classic;
}

/// The pin style with the given name, or the red push-pin.
PinStyle pinStyleById(String id) =>
    PinStyle.values.where((p) => p.name == id).firstOrNull ?? PinStyle.classic;

/// The chosen [PinStyle], for the cards. Read through [pinStyleOf]; set by
/// [buildAppTheme].
class PinLook extends ThemeExtension<PinLook> {
  const PinLook(this.style);

  final PinStyle style;

  @override
  PinLook copyWith({PinStyle? style}) => PinLook(style ?? this.style);

  @override
  PinLook lerp(ThemeExtension<PinLook>? other, double t) => this;
}

PinStyle pinStyleOf(BuildContext context) =>
    Theme.of(context).extension<PinLook>()?.style ?? PinStyle.classic;

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
/// [pin] is how the notes are held up.
ThemeData buildAppTheme(
  FontChoice font, {
  bool night = false,
  PinStyle pin = PinStyle.classic,
}) {
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
    extensions: [NoteTextScale(font.scale), NightMood(night), PinLook(pin)],
    splashFactory: InkSparkle.splashFactory,
    iconTheme: const IconThemeData(color: AppColors.ink, size: AppMetrics.icon),
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
    // The primary action is sunny paper. Destructive buttons still explicitly
    // request their warning foreground in the owning confirmation dialog.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        shape: controlShape,
        minimumSize: const Size(48, AppMetrics.target),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: night
            ? nightPaper(AppColors.accent)
            : AppColors.accent,
        foregroundColor: AppColors.ink,
        shape: controlShape,
        minimumSize: const Size(48, AppMetrics.target),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.inkSoft),
        shape: controlShape,
        minimumSize: const Size(48, AppMetrics.target),
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
      style: IconButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size.square(AppMetrics.target),
        iconSize: AppMetrics.icon,
      ),
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
