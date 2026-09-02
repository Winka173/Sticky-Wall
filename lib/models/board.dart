/// A named wall that holds its own set of notes and its own wall texture.
class Board {
  Board({
    required this.id,
    required this.name,
    this.wallIndex = 0,
    this.wallImage = '',
    this.wallImageDark = false,
    this.icon = '',
  });

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

  bool get hasWallImage => wallImage.isNotEmpty;

  factory Board.fromJson(Map<String, dynamic> json) => Board(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        wallIndex: json['wallIndex'] as int? ?? 0,
        wallImage: json['wallImage'] as String? ?? '',
        wallImageDark: json['wallImageDark'] as bool? ?? false,
        icon: json['icon'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'wallIndex': wallIndex,
        'wallImage': wallImage,
        'wallImageDark': wallImageDark,
        'icon': icon,
      };
}
