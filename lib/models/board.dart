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
    this.isPrivate = false,
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

  /// A private board (Sticky Wall Pro) opens only after the phone's lock,
  /// and keeps its notes off the widget, out of search from other boards,
  /// out of the trash list and out of reminder texts while shut.
  bool isPrivate;

  /// Marker strokes drawn straight on this wall (behind the notes), with
  /// points as fractions of the wall's size so they scale like the notes do.
  final List<DrawStroke> strokes;

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
    isPrivate: json['private'] as bool? ?? false,
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
    if (isPrivate) 'private': true,
    if (strokes.isNotEmpty) 'strokes': strokes.map((s) => s.toJson()).toList(),
  };
}
