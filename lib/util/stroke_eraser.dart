import 'dart:math' as math;
import 'dart:ui';

import '../models/draw_stroke.dart';

const _epsilon = 1e-9;
typedef _Interval = (double, double);

/// Cuts only ink under a swept circular eraser. The sweep between consecutive
/// pointer events is a capsule, so fast movement cannot skip over thin lines.
/// Unchanged strokes retain identity; cut pieces retain color, width and anchor.
List<DrawStroke> eraseStroke(
  DrawStroke stroke, {
  required Size size,
  required Offset from,
  required Offset to,
  required double radius,
}) {
  if (stroke.points.isEmpty) return [stroke];
  final reach = radius + stroke.width / 2;
  final placed = [for (final p in stroke.points) stroke.place(p, size)];
  if (placed.length == 1) {
    return _distanceToSegment(placed.first, from, to) <= reach ? [] : [stroke];
  }
  final eraserBounds = Rect.fromPoints(from, to).inflate(reach);
  final pieces = <List<Offset>>[];
  var current = <Offset>[];
  var changed = false;
  void flush() {
    if (current.isNotEmpty) pieces.add(current);
    current = [];
  }

  void add(Offset point) {
    if (current.isEmpty || (current.last - point).distanceSquared > _epsilon) {
      current.add(point);
    }
  }

  for (var i = 1; i < placed.length; i++) {
    final a = placed[i - 1];
    final b = placed[i];
    if ((a - b).distanceSquared < _epsilon) {
      if (_distanceToSegment(a, from, to) <= reach) {
        changed = true;
        flush();
      } else {
        add(a);
      }
      continue;
    }
    final cuts = Rect.fromPoints(a, b).inflate(_epsilon).overlaps(eraserBounds)
        ? _capsuleIntervals(a, b, from, to, reach)
        : <_Interval>[];
    if (cuts.isEmpty) {
      add(a);
      add(b);
      continue;
    }
    changed = true;
    var cursor = 0.0;
    for (final (start, end) in cuts) {
      if (start > cursor + _epsilon) {
        add(Offset.lerp(a, b, cursor)!);
        add(Offset.lerp(a, b, start)!);
      }
      flush();
      cursor = end;
    }
    if (cursor < 1 - _epsilon) {
      add(Offset.lerp(a, b, cursor)!);
      add(b);
    }
  }
  flush();
  return changed
      ? [for (final piece in pieces) stroke.fragment(piece, size)]
      : [stroke];
}

double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

double _distanceToSegment(Offset p, Offset a, Offset b) {
  final d = b - a;
  final length2 = d.distanceSquared;
  if (length2 < _epsilon) return (p - a).distance;
  final t = (_dot(p - a, d) / length2).clamp(0.0, 1.0);
  return (p - (a + d * t)).distance;
}

List<_Interval> _capsuleIntervals(
  Offset a,
  Offset b,
  Offset from,
  Offset to,
  double radius,
) {
  final intervals = <_Interval>[];
  final d = b - a;
  void circle(Offset center) {
    final f = a - center;
    final aa = d.distanceSquared;
    final bb = 2 * _dot(f, d);
    final cc = f.distanceSquared - radius * radius;
    final disc = bb * bb - 4 * aa * cc;
    if (disc <= 0) return;
    final root = math.sqrt(disc);
    final lo = ((-bb - root) / (2 * aa)).clamp(0.0, 1.0);
    final hi = ((-bb + root) / (2 * aa)).clamp(0.0, 1.0);
    if (hi - lo > _epsilon) intervals.add((lo, hi));
  }

  circle(from);
  final sweep = to - from;
  if (sweep.distanceSquared > _epsilon) {
    circle(to);
    final length = sweep.distance;
    final u = sweep / length;
    final n = Offset(-u.dy, u.dx);
    var lo = 0.0, hi = 1.0;
    bool slab(double origin, double delta, double min, double max) {
      if (delta.abs() < _epsilon) return origin >= min && origin <= max;
      final x = (min - origin) / delta;
      final y = (max - origin) / delta;
      lo = math.max(lo, math.min(x, y));
      hi = math.min(hi, math.max(x, y));
      return hi - lo > _epsilon;
    }

    if (slab(_dot(a - from, u), _dot(d, u), 0, length) &&
        slab(_dot(a - from, n), _dot(d, n), -radius, radius)) {
      intervals.add((lo, hi));
    }
  }
  intervals.sort((a, b) => a.$1.compareTo(b.$1));
  final merged = <_Interval>[];
  for (final cut in intervals) {
    if (merged.isEmpty || cut.$1 > merged.last.$2 + _epsilon) {
      merged.add(cut);
    } else {
      merged[merged.length - 1] = (
        merged.last.$1,
        math.max(merged.last.$2, cut.$2),
      );
    }
  }
  return merged;
}
