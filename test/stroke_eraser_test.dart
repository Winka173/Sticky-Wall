import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/models/draw_stroke.dart';
import 'package:sticky_wall/util/stroke_eraser.dart';

void main() {
  const size = Size(400, 600);
  DrawStroke line({bool legacy = false, double width = 4}) => DrawStroke(
    color: 0x66FF5500,
    width: width,
    refWidth: legacy ? null : size.width,
    refHeight: legacy ? null : size.height,
    points: const [Offset(.1, .5), Offset(.9, .5)],
  );
  List<DrawStroke> rub(
    DrawStroke stroke,
    Offset a,
    Offset b, {
    double radius = 14,
  }) => eraseStroke(stroke, size: size, from: a, to: b, radius: radius);

  test('a tap removes the middle of a sparse line, keeping both ends', () {
    final original = line();
    final pieces = rub(
      original,
      const Offset(200, 300),
      const Offset(200, 300),
    );
    expect(pieces, hasLength(2));
    expect(
      pieces.first.place(pieces.first.points.first, size),
      const Offset(40, 300),
    );
    expect(
      pieces.first.place(pieces.first.points.last, size).dx,
      closeTo(184, 1e-6),
    );
    expect(
      pieces.last.place(pieces.last.points.first, size).dx,
      closeTo(216, 1e-6),
    );
    expect(
      pieces.last.place(pieces.last.points.last, size),
      const Offset(360, 300),
    );
    expect(original.points, const [
      Offset(.1, .5),
      Offset(.9, .5),
    ], reason: 'Undo keeps the untouched original');
    expect(
      pieces.every(
        (s) => s.color == original.color && s.width == original.width,
      ),
      isTrue,
    );
  });
  test('fast movement cuts between pointer samples, including a diagonal', () {
    for (final sweep in [
      (const Offset(200, 200), const Offset(200, 400)),
      (const Offset(100, 200), const Offset(300, 400)),
    ]) {
      final pieces = rub(line(), sweep.$1, sweep.$2);
      expect(pieces, hasLength(2));
      expect(
        pieces.first.place(pieces.first.points.last, size).dx,
        lessThan(200),
      );
      expect(
        pieces.last.place(pieces.last.points.first, size).dx,
        greaterThan(200),
      );
    }
  });
  test('an oblique capsule removes a continuous interval along a line', () {
    final pieces = rub(line(), const Offset(100, 302), const Offset(300, 302));
    expect(pieces, hasLength(2));
    expect(
      pieces.first.place(pieces.first.points.last, size).dx,
      lessThan(100),
    );
    expect(
      pieces.last.place(pieces.last.points.first, size).dx,
      greaterThan(300),
    );
  });
  test('misses preserve identity; a full sweep removes all of the ink', () {
    final original = line();
    expect(
      identical(
        rub(original, const Offset(0, 0), const Offset(400, 0)).single,
        original,
      ),
      isTrue,
    );
    expect(
      rub(original, const Offset(0, 300), const Offset(400, 300)),
      isEmpty,
    );
  });
  test('dots and repeated points are handled without invalid coordinates', () {
    for (final points in [
      <Offset>[],
      [const Offset(.5, .5)],
      [const Offset(.5, .5), const Offset(.5, .5)],
    ]) {
      final dot = DrawStroke(color: 0xFF000000, width: 4, points: points);
      final pieces = rub(dot, const Offset(200, 300), const Offset(200, 300));
      expect(pieces, points.isEmpty ? hasLength(1) : isEmpty);
    }
  });
  test('a loop can be cut into multiple independent surviving pieces', () {
    final stroke = DrawStroke(
      color: 0xFF000000,
      width: 4,
      points: const [
        Offset(.1, .3),
        Offset(.9, .3),
        Offset(.9, .7),
        Offset(.1, .7),
        Offset(.1, .3),
      ],
    );
    final pieces = rub(stroke, const Offset(200, 100), const Offset(200, 500));
    expect(pieces, hasLength(3));
    for (final piece in pieces) {
      final xs = piece.points.map((p) => piece.place(p, size).dx);
      expect(
        xs.every((x) => x < 200) || xs.every((x) => x > 200),
        isTrue,
        reason: 'Never reconnect across the erased gap',
      );
    }
  });
  test(
    'fragments keep their original placement on other screens and after saving',
    () {
      final original = line();
      final pieces = rub(
        original,
        const Offset(200, 300),
        const Offset(200, 300),
      );
      const landscape = Size(900, 400);
      for (final piece in pieces) {
        for (final restored in [
          piece,
          piece.copy(),
          DrawStroke.fromJson(piece.toJson()),
        ]) {
          expect(restored.anchor, const Offset(.5, .5));
          for (final point in restored.points) {
            final expected = original.place(point, landscape);
            final actual = restored.place(point, landscape);
            expect(actual.dx, closeTo(expected.dx, 1e-6));
            expect(actual.dy, closeTo(expected.dy, 1e-6));
          }
        }
      }
    },
  );
  test('repeated cuts retain the shared anchor and untouched endpoints', () {
    final first = rub(line(), const Offset(200, 300), const Offset(200, 300));
    final second = [
      for (final p in first)
        ...rub(p, const Offset(100, 300), const Offset(100, 300)),
    ];
    expect(second, hasLength(3));
    expect(second.every((p) => p.anchor == const Offset(.5, .5)), isTrue);
    expect(
      second.first.place(second.first.points.first, size),
      const Offset(40, 300),
    );
    expect(
      second.last.place(second.last.points.last, size),
      const Offset(360, 300),
    );
  });
  test(
    'old normalized strokes still scale as before after a partial erase',
    () {
      final original = line(legacy: true);
      final pieces = rub(
        original,
        const Offset(200, 300),
        const Offset(200, 300),
      );
      expect(pieces, hasLength(2));
      expect(
        pieces.every((p) => p.anchor == null && p.refWidth == null),
        isTrue,
      );
      for (final p in pieces) {
        for (final point in p.points) {
          expect(
            p.place(point, const Size(800, 1200)),
            original.place(point, const Size(800, 1200)),
          );
        }
      }
    },
  );
}
