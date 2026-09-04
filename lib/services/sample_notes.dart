import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/draw_stroke.dart';
import '../models/note.dart';
import '../widgets/drawing_canvas.dart' show kDrawingAspect;
import '../widgets/wall_view.dart' show WallView;

/// The notes a brand-new wall starts with: stickies that each teach one
/// gesture (plus a doodle, so the drawing type is discovered too), and a
/// thread between two of them so the yarn is discovered by seeing it, not by
/// reading about it.
class SampleNotes {
  const SampleNotes({required this.notes, required this.links});

  final List<Note> notes;
  final List<NoteLink> links;

  /// Where each sample sits, in logical pixels from the wall's top-left.
  /// Real distances, not fractions: a note stores its place as a fraction of
  /// the wall's free travel, so an arrangement designed on a phone would
  /// stretch across a tablet — two columns half a screen apart with a hole
  /// between them — and pile up on a short wall. Keeping the distances puts
  /// the same tidy cluster on every screen.
  static const _spots = [
    Offset(5, 17), // drag me
    Offset(220, 66), // long-press me
    Offset(7, 220), // checklist
    Offset(218, 303), // thread
    // Under the left column: centred at the foot it would clip the corner of
    // the thread note above it (measured, see sample_layout_test).
    Offset(16, 441), // doodle
  ];

  /// The wall the distances above were laid out against (a 393dp phone).
  static const _designedFor = Size(393, 631);

  /// [spot] as the fractions a note stores, for a wall of [wall] logical
  /// pixels. Clamped, so a screen smaller than the design still lands every
  /// card on the wall.
  static Offset _fractionOf(Offset spot, Size? wall) {
    final size = wall ?? _designedFor;
    // Never divide by less than the design: on a wall smaller than the phone
    // these distances were drawn for, the arrangement shrinks with the wall
    // instead of piling every card against the clamp.
    final rangeX = math.max(
      size.width - WallView.cardWidth,
      _designedFor.width - WallView.cardWidth,
    );
    final rangeY = math.max(
      size.height - WallView.noteBottomInset,
      _designedFor.height - WallView.noteBottomInset,
    );
    return Offset(
      (spot.dx / rangeX).clamp(0.0, 1.0),
      (spot.dy / rangeY).clamp(0.0, 1.0),
    );
  }

  /// [wall] is the wall's usable size (see HomeScreen.wallSizeFor); the
  /// design size stands in when it is not known.
  factory SampleNotes.build(
    AppLocalizations l10n,
    String boardId, {
    Size? wall,
  }) {
    const uuid = Uuid();
    final now = DateTime.now();
    // Slightly staggered creation times keep the list/grid order stable.
    Note note(
      int i,
      String content, {
      required int color,
      NoteType type = NoteType.normal,
      List<ChecklistItem>? checklist,
      List<DrawStroke>? strokes,
    }) {
      final at = _fractionOf(_spots[i], wall);
      return Note(
        guid: uuid.v4(),
        content: content,
        createdAt: now.subtract(Duration(minutes: 5 - i)),
        boardId: boardId,
        type: type,
        colorIndex: color,
        x: at.dx,
        y: at.dy,
        checklist: checklist,
        strokes: strokes,
      );
    }

    final drag = note(0, l10n.sampleDrag, color: 0);
    final longPress = note(1, l10n.sampleLongPress, color: 1);
    final checklist = note(
      2,
      l10n.sampleChecklistTitle,
      color: 3,
      type: NoteType.checklist,
      checklist: [
        ChecklistItem(text: l10n.sampleChecklist1),
        ChecklistItem(text: l10n.sampleChecklist2),
        ChecklistItem(text: l10n.sampleChecklist3),
      ],
    );
    final thread = note(3, l10n.sampleThread, color: 2);
    final drawing = note(
      4,
      l10n.sampleDrawing,
      color: 4,
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

    List<Offset> arc(
      double cx,
      double cy,
      double r,
      double from,
      double to, {
      int steps = 24,
    }) {
      return [
        for (var i = 0; i <= steps; i++)
          () {
            final t = from + (to - from) * i / steps;
            return Offset(
              cx + r * math.cos(t),
              cy + r * kDrawingAspect * math.sin(t),
            );
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
            final y =
                13 * math.cos(t) -
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
      DrawStroke(
        color: ink,
        width: w,
        points: arc(cx, cy, 0.2, 0, 2 * math.pi),
      ),
      for (final dx in [-0.07, 0.07])
        DrawStroke(
          color: ink,
          width: w + 1,
          points: [Offset(cx + dx, cy - 0.13), Offset(cx + dx, cy - 0.08)],
        ),
      DrawStroke(
        color: ink,
        width: w,
        points: arc(cx, cy, 0.11, math.pi * 0.2, math.pi * 0.8, steps: 12),
      ),
      DrawStroke(color: red, width: w, points: heart(0.74, 0.47, 0.011)),
    ];
  }
}
