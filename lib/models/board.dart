import 'package:flutter/painting.dart';

import 'draw_stroke.dart';

/// A named wall that holds its own set of notes and its own wall texture.
class Board {
  Board({
    required this.id,
    required this.name,
    this.wallIndex = 0,
    this.wallImage = '',
    this.wallImageDark = false,
    this.icon = '',
    this.bold = false,
    this.italic = false,
    this.underline = false,
    List<DrawStroke>? strokes,
  }) : strokes = strokes ?? [];

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

  /// Optional emoji shown on the board's tab.
  String icon;

  /// How the name is written on the tab. Whole-name formatting, so it reads
  /// the same everywhere the board is listed.
  bool bold;
  bool italic;
  bool underline;

  /// Marker strokes drawn straight on this wall (behind the notes), with
  /// points as fractions of the wall's size so they scale like the notes do.
  final List<DrawStroke> strokes;

  bool get hasWallImage => wallImage.isNotEmpty;

  /// [base] with this board's formatting laid on top. Anything not switched
  /// on is left as [base] has it, so a selected tab can still be bold.
  TextStyle decorate(TextStyle base) => base.copyWith(
    fontWeight: bold ? FontWeight.bold : null,
    fontStyle: italic ? FontStyle.italic : null,
    decoration: underline ? TextDecoration.underline : null,
  );

  factory Board.fromJson(Map<String, dynamic> json) => Board(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    wallIndex: json['wallIndex'] as int? ?? 0,
    wallImage: json['wallImage'] as String? ?? '',
    wallImageDark: json['wallImageDark'] as bool? ?? false,
    icon: json['icon'] as String? ?? '',
    bold: json['bold'] as bool? ?? false,
    italic: json['italic'] as bool? ?? false,
    underline: json['underline'] as bool? ?? false,
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
    'icon': icon,
    'bold': bold,
    'italic': italic,
    'underline': underline,
    if (strokes.isNotEmpty) 'strokes': strokes.map((s) => s.toJson()).toList(),
  };
}
