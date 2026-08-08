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
          for (final p in (json['points'] as List<dynamic>? ?? []))
            Offset(
              (p['x'] as num).toDouble(),
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

  DrawStroke copy() => DrawStroke(
        color: color,
        width: width,
        points: List<Offset>.from(points),
      );
}
