import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/draw_stroke.dart';
import '../models/note.dart';
import '../widgets/drawing_canvas.dart' show kDrawingAspect;

/// The notes a brand-new wall starts with: stickies that each teach one
/// gesture (plus a doodle, so the drawing type is discovered too), and a
/// thread between two of them so the yarn is discovered by seeing it, not by
/// reading about it.
class SampleNotes {
  const SampleNotes({required this.notes, required this.links});

  final List<Note> notes;
  final List<NoteLink> links;

  factory SampleNotes.build(AppLocalizations l10n, String boardId) {
    const uuid = Uuid();
    final now = DateTime.now();
    // Slightly staggered creation times keep the list/grid order stable.
    Note note(
      int i,
      String content, {
      required int color,
      required double x,
      required double y,
      NoteType type = NoteType.normal,
      List<ChecklistItem>? checklist,
      List<DrawStroke>? strokes,
    }) =>
        Note(
          guid: uuid.v4(),
          content: content,
          createdAt: now.subtract(Duration(minutes: 5 - i)),
          boardId: boardId,
          type: type,
          colorIndex: color,
          x: x,
          y: y,
          checklist: checklist,
          strokes: strokes,
        );

    // x/y are fractions of the free travel (wall minus one card), so two
    // columns need x near 0 and near 1 to sit apart on a phone-width wall.
    final drag = note(0, l10n.sampleDrag, color: 0, x: 0.02, y: 0.03);
    final longPress = note(1, l10n.sampleLongPress, color: 1, x: 0.98, y: 0.12);
    final checklist = note(
      2,
      l10n.sampleChecklistTitle,
      color: 3,
      x: 0.03,
      y: 0.40,
      type: NoteType.checklist,
      checklist: [
        ChecklistItem(text: l10n.sampleChecklist1),
        ChecklistItem(text: l10n.sampleChecklist2),
        ChecklistItem(text: l10n.sampleChecklist3),
      ],
    );
    final thread = note(3, l10n.sampleThread, color: 2, x: 0.97, y: 0.55);
    // Bottom middle, clear of the FAB in the bottom-right corner.
    final drawing = note(
      4,
      l10n.sampleDrawing,
      color: 4,
      x: 0.5,
      y: 0.8,
      type: NoteType.drawing,
      strokes: _doodle(),
    );

    return SampleNotes(
      notes: [drag, longPress, checklist, thread, drawing],
      links: [NoteLink(thread.guid, drag.guid)],
    );
  }

  /// A smiley and a heart, in the pen colors the drawing editor offers.
  /// Points are normalized to the drawing area, whose aspect is
  /// [kDrawingAspect]; vertical radii are stretched by it so circles stay
  /// round.
  static List<DrawStroke> _doodle() {
    const ink = 0xFF3B372F;
    const red = 0xFFC62828;
    const w = 4.0;

    List<Offset> arc(double cx, double cy, double r, double from, double to,
        {int steps = 24}) {
      return [
        for (var i = 0; i <= steps; i++)
          () {
            final t = from + (to - from) * i / steps;
            return Offset(
                cx + r * math.cos(t), cy + r * kDrawingAspect * math.sin(t));
          }(),
      ];
    }

    // Classic heart curve, scaled into the right half of the area.
    List<Offset> heart(double cx, double cy, double s, {int steps = 40}) {
      return [
        for (var i = 0; i <= steps; i++)
          () {
            final t = i / steps * 2 * math.pi;
            final x = 16 * math.pow(math.sin(t), 3).toDouble();
            final y = 13 * math.cos(t) -
                5 * math.cos(2 * t) -
                2 * math.cos(3 * t) -
                math.cos(4 * t);
            return Offset(cx + s * x, cy - s * kDrawingAspect * y);
          }(),
      ];
    }

    const cx = 0.3, cy = 0.5;
    return [
      // Face outline, two dash eyes, smile.
      DrawStroke(color: ink, width: w, points: arc(cx, cy, 0.2, 0, 2 * math.pi)),
      for (final dx in [-0.07, 0.07])
        DrawStroke(color: ink, width: w + 1, points: [
          Offset(cx + dx, cy - 0.13),
          Offset(cx + dx, cy - 0.08),
        ]),
      DrawStroke(
        color: ink,
        width: w,
        points: arc(cx, cy, 0.11, math.pi * 0.2, math.pi * 0.8, steps: 12),
      ),
      DrawStroke(color: red, width: w, points: heart(0.74, 0.47, 0.011)),
    ];
  }
}
