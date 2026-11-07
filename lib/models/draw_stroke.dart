import 'dart:ui';

/// One freehand stroke of a drawing note. Points are stored normalized to the
/// 0..1 range of the drawing area, so a drawing scales to any card size.
class DrawStroke {
  DrawStroke({
    required this.color,
    required this.width,
    required this.points,
    this.refWidth,
    this.refHeight,
    this.anchor,
  });

  /// ARGB value.
  final int color;
  final double width;
  final List<Offset> points;

  /// For a stroke drawn on the wall: the wall's size, in logical pixels,
  /// when it was drawn. With it the stroke keeps its shape and size on any
  /// screen (a portrait phone and a landscape tablet see the same letter);
  /// only where it sits follows the wall, as a note's place does. Null for
  /// a drawing note (it scales with its card) and for older wall strokes.
  final double? refWidth;
  final double? refHeight;

  /// Cut pieces share the original wall stroke's placement anchor, so they
  /// stay aligned when the wall is shown on another screen size.
  final Offset? anchor;

  Offset? _center;

  /// The middle of the stroke's points (0..1 of the area): the part of a
  /// wall stroke that moves with the wall.
  Offset get _middle {
    final cached = _center;
    if (cached != null) return cached;
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return _center = Offset((minX + maxX) / 2, (minY + maxY) / 2);
  }

  /// Where point [p] of this stroke goes on an area of [size].
  Offset place(Offset p, Size size) {
    final rw = refWidth;
    final rh = refHeight;
    if (rw == null || rh == null || rw <= 0 || rh <= 0) {
      return Offset(p.dx * size.width, p.dy * size.height);
    }
    final c = anchor ?? _middle;
    return Offset(
      c.dx * size.width + (p.dx - c.dx) * rw,
      c.dy * size.height + (p.dy - c.dy) * rh,
    );
  }

  /// A surviving piece, supplied in the current wall's logical coordinates.
  /// Keep the original anchor rather than recentering each piece separately.
  DrawStroke fragment(List<Offset> placed, Size size) {
    final rw = refWidth;
    final rh = refHeight;
    final fixed = rw != null && rh != null && rw > 0 && rh > 0;
    final center = anchor ?? _middle;
    return DrawStroke(
      color: color,
      width: width,
      refWidth: refWidth,
      refHeight: refHeight,
      anchor: fixed ? center : anchor,
      points: [
        for (final p in placed)
          fixed
              ? Offset(
                  center.dx + (p.dx - center.dx * size.width) / rw,
                  center.dy + (p.dy - center.dy * size.height) / rh,
                )
              : Offset(p.dx / size.width, p.dy / size.height),
      ],
    );
  }

  /// Adds a point while the stroke is being drawn.
  void addPoint(Offset p) {
    points.add(p);
    _center = null;
  }

  factory DrawStroke.fromJson(Map<String, dynamic> json) => DrawStroke(
    color: json['color'] as int? ?? 0xFF000000,
    width: (json['width'] as num?)?.toDouble() ?? 3.0,
    refWidth: (json['rw'] as num?)?.toDouble(),
    refHeight: (json['rh'] as num?)?.toDouble(),
    anchor: json['anchor'] is Map<String, dynamic>
        ? Offset(
            ((json['anchor'] as Map<String, dynamic>)['x'] as num).toDouble(),
            ((json['anchor'] as Map<String, dynamic>)['y'] as num).toDouble(),
          )
        : null,
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
    if (refWidth != null) 'rw': refWidth,
    if (refHeight != null) 'rh': refHeight,
    if (anchor case final a?) 'anchor': {'x': a.dx, 'y': a.dy},
    'points': [
      for (final p in points) {'x': p.dx, 'y': p.dy},
    ],
  };

  DrawStroke copy() => DrawStroke(
    color: color,
    width: width,
    points: List<Offset>.from(points),
    refWidth: refWidth,
    refHeight: refHeight,
    anchor: anchor,
  );
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
