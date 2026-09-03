import 'dart:ui';

/// One freehand stroke of a drawing note. Points are stored normalized to the
/// 0..1 range of the drawing area, so a drawing scales to any card size.
class DrawStroke {
  DrawStroke({required this.color, required this.width, required this.points});

  /// ARGB value.
  final int color;
  final double width;
  final List<Offset> points;

  factory DrawStroke.fromJson(Map<String, dynamic> json) => DrawStroke(
    color: json['color'] as int? ?? 0xFF000000,
    width: (json['width'] as num?)?.toDouble() ?? 3.0,
    points: [
      for (final p in (json['points'] as List<dynamic>? ?? const []))
        Offset(
          ((p as Map<String, dynamic>)['x'] as num).toDouble(),
          (p['y'] as num).toDouble(),
        ),
    ],
  );

  Map<String, dynamic> toJson() => {
    'color': color,
    'width': width,
    'points': [
      for (final p in points) {'x': p.dx, 'y': p.dy},
    ],
  };

  DrawStroke copy() =>
      DrawStroke(color: color, width: width, points: List<Offset>.from(points));
}

/// The faint guide pattern printed on a drawing canvas.
enum CanvasPattern { plain, ruled, grid, dots }

/// The paper a drawing note is drawn on: a background tone plus a guide
/// pattern. Immutable; the editor swaps in a new value via [copyWith].
class DrawCanvas {
  const DrawCanvas({
    this.color = defaultColor,
    this.pattern = CanvasPattern.plain,
  });

  /// Off-white — what every drawing note used before canvases were editable.
  static const defaultColor = 0xFFFFFDF5;

  /// ARGB background tone (one of [DrawCanvas.tones] when set from the UI).
  final int color;
  final CanvasPattern pattern;

  /// Background tones offered by the editor: papers first, then a chalkboard.
  static const tones = [
    defaultColor, // white
    0xFFFFF3C4, // cream
    0xFFFCE4EC, // blush
    0xFFE3F2FD, // sky
    0xFFE0F2EE, // mint
    0xFFD9B27C, // kraft
    0xFF2E3A36, // chalkboard
  ];

  /// True for the chalkboard-like tones, where guides and the default pen
  /// should be light instead of dark.
  bool get isDark => Color(color).computeLuminance() < 0.35;

  DrawCanvas copyWith({int? color, CanvasPattern? pattern}) =>
      DrawCanvas(color: color ?? this.color, pattern: pattern ?? this.pattern);

  factory DrawCanvas.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DrawCanvas();
    final name = json['pattern'] as String?;
    return DrawCanvas(
      color: json['color'] as int? ?? defaultColor,
      pattern:
          CanvasPattern.values
              .where((p) => p.name == name)
              .cast<CanvasPattern?>()
              .firstOrNull ??
          CanvasPattern.plain,
    );
  }

  Map<String, dynamic> toJson() => {'color': color, 'pattern': pattern.name};

  @override
  bool operator ==(Object other) =>
      other is DrawCanvas && other.color == color && other.pattern == pattern;

  @override
  int get hashCode => Object.hash(color, pattern);
}
