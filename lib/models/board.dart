/// A named wall that holds its own set of notes and its own wall texture.
class Board {
  Board({required this.id, required this.name, this.wallIndex = 0});

  final String id;
  String name;

  /// Index into the [walls] list in theme.dart — each board can look different.
  int wallIndex;

  factory Board.fromJson(Map<String, dynamic> json) => Board(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        wallIndex: json['wallIndex'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'wallIndex': wallIndex,
      };
}
