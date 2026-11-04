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

  // Sample order in the layouts below: drag me, thread, long-press me,
  // checklist, doodle. "Drag me" and the thread note always sit side by
  // side, pin level with pin, so the yarn tied between them runs above both
  // cards instead of across their words.

  /// Where each sample sits on a phone in portrait, in logical pixels from
  /// the arrangement's top-left. Real distances, not fractions: a note
  /// stores its place as a fraction of the wall's free travel, so fractions
  /// designed on a phone would stretch across a tablet, two columns half a
  /// screen apart, and pile up on a short wall.
  static const _portrait = [
    Offset(0, 0), // drag me
    Offset(201, 5), // thread
    // The longest card, below the short thread note: a card above a pin
    // would hide it, and that pin is the one the sample asks you to drag.
    Offset(201, 286), // long-press me
    Offset(0, 203), // checklist
    // Under the left column: centred at the foot it would clip the corner of
    // the thread note above it (measured, see sample_layout_test).
    Offset(8, 424), // doodle
  ];

  /// The wall the portrait distances were laid out against (a 393dp phone).
  static const _designedFor = Size(393, 631);

  /// Card footprint used to lay the samples out in rows: a sample card is
  /// [WallView.cardWidth] wide and about 195dp tall with its pin.
  static const _cardHeight = 196.0;
  static const _minGap = 12.0;
  static const _rowGap = 24.0;

  /// Small ups and downs so a row reads as stuck up by hand, not printed.
  static const _stagger = <double>[0, 5, 0, 8, 2];

  /// Columns the wall has room for, gaps included (1 to 5).
  static int _columns(double width) {
    final fit =
        ((width - 2 * _minGap + _minGap) / (WallView.cardWidth + _minGap))
            .floor();
    return fit.clamp(1, 5);
  }

  /// Spots for a wall of [wall], arrangement-relative, before centring.
  /// Two columns use the hand-tuned phone layout; wider walls put the five
  /// cards in rows, as many per row as fit, with the gap shared out evenly.
  static List<Offset> _layout(Size wall) {
    final columns = _columns(wall.width);
    if (columns <= 2) return _portrait;
    final spare = wall.width - 2 * _minGap - columns * WallView.cardWidth;
    final gap = (spare / math.max(1, columns - 1)).clamp(_minGap, 40.0);
    final step = WallView.cardWidth + gap;
    return [
      for (var i = 0; i < 5; i++)
        Offset(
          (i % columns) * step,
          (i ~/ columns) * (_cardHeight + _rowGap) + _stagger[i],
        ),
    ];
  }

  /// Where the samples go on [wall], as the fractions a note stores. The
  /// arrangement is centred across the wall and sits a little above the
  /// middle when there is height to spare, so it never hugs one corner of a
  /// big screen. On a wall too small for it, it shrinks with the wall
  /// instead of piling every card against the edge.
  static List<Offset> _fractions(Size? wall) {
    final size = (wall == null || wall.isEmpty) ? _designedFor : wall;
    final spots = _layout(size);
    final right = spots.map((o) => o.dx).reduce(math.max) + WallView.cardWidth;
    final bottom = spots.map((o) => o.dy).reduce(math.max) + _cardHeight;
    final left = math.max(_minGap, (size.width - right) / 2);
    final roomY = size.height - WallView.noteBottomInset - bottom;
    final top = roomY > 0 ? 17.0 + math.min(roomY * 0.35, 120.0) : 17.0;
    final placed = [for (final o in spots) o + Offset(left, top)];
    // Never divide by less than the arrangement needs: on a wall smaller
    // than it, it shrinks with the wall instead of clamping into a pile.
    final rangeX = math.max(
      size.width - WallView.cardWidth,
      placed.map((o) => o.dx).reduce(math.max),
    );
    final rangeY = math.max(
      size.height - WallView.noteBottomInset,
      math.max(
        _designedFor.height - WallView.noteBottomInset,
        placed.map((o) => o.dy).reduce(math.max),
      ),
    );
    return [
      for (final o in placed)
        Offset(
          rangeX <= 0 ? 0 : (o.dx / rangeX).clamp(0.0, 1.0),
          rangeY <= 0 ? 0 : (o.dy / rangeY).clamp(0.0, 1.0),
        ),
    ];
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
    final spots = _fractions(wall);
    // Slightly staggered creation times keep the list/grid order stable.
    Note note(
      int i,
      String content, {
      required int color,
      NoteType type = NoteType.normal,
      List<ChecklistItem>? checklist,
      List<DrawStroke>? strokes,
    }) {
      final at = spots[i];
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
    final longPress = note(2, l10n.sampleLongPress, color: 1);
    final checklist = note(
      3,
      l10n.sampleChecklistTitle,
      color: 3,
      type: NoteType.checklist,
      checklist: [
        ChecklistItem(text: l10n.sampleChecklist1),
        ChecklistItem(text: l10n.sampleChecklist2),
        ChecklistItem(text: l10n.sampleChecklist3),
      ],
    );
    final thread = note(1, l10n.sampleThread, color: 2);
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
