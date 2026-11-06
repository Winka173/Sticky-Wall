import 'draw_stroke.dart';

/// A named wall that holds its own set of notes and its own wall texture.
class Board {
  Board({
    required this.id,
    required this.name,
    this.wallIndex = 0,
    this.wallImage = '',
    this.wallImageDark = false,
    String? savedWallImage,
    bool? savedWallImageDark,
    this.icon = '',
    this.themeId = '',
    this.fontId = '',
    this.pinStyle = '',
    this.favorite = false,
    this.isPrivate = false,
    this.deletedAt,
    this.deletedIndex = 0,
    List<DrawStroke>? strokes,
  }) : strokes = strokes ?? [],
       savedWallImage = savedWallImage ?? wallImage,
       savedWallImageDark = savedWallImageDark ?? wallImageDark;

  final String id;
  String name;

  /// Index into the [walls] list in theme.dart — each board can look different.
  int wallIndex;

  /// A photo of the user's own chosen as the wall, stored as a file name in
  /// the app's `wall_images` folder (see `ImageService`); empty for a texture.
  String wallImage;

  /// Whether that photo is dark overall, which decides the scrim that keeps
  /// writing on top of it legible.
  bool wallImageDark;

  /// The board's own photo, kept while the user browses the textures so it
  /// is one tap to go back to (equals [wallImage] while it is on show). The
  /// file goes only when another photo replaces it or the board is deleted.
  String savedWallImage;
  bool savedWallImageDark;

  /// Optional emoji shown on the board's tab.
  String icon;

  /// The theme pack last applied (see theme_packs.dart), or empty.
  String themeId;

  /// The board's own handwriting and pin, set by a theme pack; empty means
  /// the ones chosen in Customize. Drawn even without Pro, like any look a
  /// note already has.
  String fontId;
  String pinStyle;

  /// Pinned to the top of *All boards*.
  bool favorite;

  /// A private board (Sticky Wall Pro) opens only after the phone's lock,
  /// and keeps its notes off the widget, out of search from other boards,
  /// out of the trash list and out of reminder texts while shut.
  bool isPrivate;

  /// Marker strokes drawn straight on this wall (behind the notes), with
  /// points as fractions of the wall's size so they scale like the notes do.
  final List<DrawStroke> strokes;

  /// When the board went to the Trash, with everything on it; null for a
  /// board in use. A board in the Trash keeps its notes, threads, drawing
  /// and files untouched until it is restored or its 30 days run out.
  DateTime? deletedAt;

  /// Where its tab stood when it was deleted, so Restore puts it back there.
  int deletedIndex;

  bool get hasWallImage => wallImage.isNotEmpty;

  bool get hasSavedWallImage => savedWallImage.isNotEmpty;

  factory Board.fromJson(Map<String, dynamic> json) => Board(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    wallIndex: json['wallIndex'] as int? ?? 0,
    wallImage: json['wallImage'] as String? ?? '',
    wallImageDark: json['wallImageDark'] as bool? ?? false,
    // Absent before photos were kept: falls back to the photo on show.
    savedWallImage: json['savedWallImage'] as String?,
    savedWallImageDark: json['savedWallImageDark'] as bool?,
    // Saves from 1.3 and earlier may carry 'bold' / 'italic' / 'underline'
    // for the name. Names are plain text since 1.4: the words are kept and
    // the flags dropped (they are not written back).
    icon: json['icon'] as String? ?? '',
    themeId: json['theme'] as String? ?? '',
    fontId: json['font'] as String? ?? '',
    pinStyle: json['pin'] as String? ?? '',
    favorite: json['favorite'] as bool? ?? false,
    isPrivate: json['private'] as bool? ?? false,
    deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
    deletedIndex: json['deletedIndex'] as int? ?? 0,
    strokes: (json['strokes'] as List<dynamic>? ?? [])
        .map((e) => DrawStroke.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'wallIndex': wallIndex,
    'wallImage': wallImage,
    'wallImageDark': wallImageDark,
    if (savedWallImage.isNotEmpty) 'savedWallImage': savedWallImage,
    if (savedWallImage.isNotEmpty) 'savedWallImageDark': savedWallImageDark,
    'icon': icon,
    if (themeId.isNotEmpty) 'theme': themeId,
    if (fontId.isNotEmpty) 'font': fontId,
    if (pinStyle.isNotEmpty) 'pin': pinStyle,
    if (favorite) 'favorite': true,
    if (isPrivate) 'private': true,
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    if (deletedAt != null) 'deletedIndex': deletedIndex,
    if (strokes.isNotEmpty) 'strokes': strokes.map((s) => s.toJson()).toList(),
  };
}
