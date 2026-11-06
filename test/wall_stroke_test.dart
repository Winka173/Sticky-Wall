import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/models/draw_stroke.dart';

/// A line drawn on the wall keeps its shape and size on any screen; only
/// where it sits follows the wall (as a note's place does).
void main() {
  // A 100 x 100 px square drawn on a 400 x 600 portrait wall, centred at
  // (200, 300).
  const portrait = Size(400, 600);
  final square = DrawStroke(
    color: 0xFF000000,
    width: 3,
    points: [
      for (final (x, y) in [(150.0, 250.0), (250.0, 250.0), (250.0, 350.0)])
        Offset(x / portrait.width, y / portrait.height),
    ],
    refWidth: portrait.width,
    refHeight: portrait.height,
  );

  test('on the screen it was drawn on, every point is where it was', () {
    expect(square.place(square.points[0], portrait), const Offset(150, 250));
    expect(square.place(square.points[2], portrait), const Offset(250, 350));
  });

  test('on a landscape wall the square stays a 100 px square, at the same '
      'place on the wall', () {
    const landscape = Size(900, 400);
    final a = square.place(square.points[0], landscape);
    final b = square.place(square.points[1], landscape);
    final c = square.place(square.points[2], landscape);
    expect((b - a).dx, closeTo(100, 1e-9));
    expect((c - b).dy, closeTo(100, 1e-9));
    // Its middle sits at the same fraction of the wall: (0.5, 0.5).
    expect((a + c) / 2, const Offset(450, 200));
  });

  test('the size is saved with it; older strokes stretch as before', () {
    final back = DrawStroke.fromJson(square.toJson());
    expect(back.refWidth, 400);
    expect(back.place(back.points[0], const Size(900, 400)).dx, 400);

    final old = DrawStroke.fromJson({
      'color': 0xFF000000,
      'width': 3,
      'points': [
        {'x': 0.5, 'y': 0.5},
      ],
    });
    expect(old.refWidth, isNull);
    expect(
      old.place(old.points[0], const Size(900, 400)),
      const Offset(450, 200),
    );
  });
}
