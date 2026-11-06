import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../theme.dart';
import '../widgets/add_note_button.dart';
import '../widgets/note_views.dart';
import '../widgets/wall_background.dart';
import 'guide_motion.dart';

/// The practice's steps: add a note, move it, tie it, done.
enum PracticeStep { add, move, tie, done }

/// A practice wall: a cork wall with two notes on it, the yellow paper that
/// adds a note, and nothing behind it. Notes here are made on the spot and
/// never reach the app's boards: nothing is saved.
///
/// Everything is dark except the one thing to do, in a lit window with a
/// label beside it: tap the yellow paper (a note appears), drag the note
/// onto the dashed spot, pull its red pin onto another note. A line at the
/// top says what is on screen; Next, at the bottom, does a step for anyone
/// who cannot make the gesture.
///
/// [top] and [bottom] leave room for the guide's own bar and the system's.
/// With [still] it is a picture of that step for the manual: no top line,
/// no Next, the thread half pulled on the tie step; the caller makes it
/// inert.
class PracticeWall extends StatefulWidget {
  const PracticeWall({
    super.key,
    this.onStep,
    this.top = 16,
    this.bottom = 0,
    this.still,
  });

  /// Told each step as it begins (done last).
  final ValueChanged<PracticeStep>? onStep;
  final double top;
  final double bottom;
  final PracticeStep? still;

  @override
  State<PracticeWall> createState() => PracticeWallState();
}

class PracticeWallState extends State<PracticeWall> {
  late PracticeStep step = widget.still ?? PracticeStep.add;

  final _stage = GlobalKey();
  final _addKey = GlobalKey();
  final _newKey = GlobalKey();
  final _spotKey = GlobalKey();
  final _dayKey = GlobalKey();
  final _mumKey = GlobalKey();

  /// Where the new note is while it is being dragged (or was let go short
  /// of the spot); null: where it appeared, or on the spot once moved.
  Offset? _free;
  bool _dragging = false;

  /// The end of a thread being pulled out of the pin, in local coordinates.
  Offset? _pull;

  /// The note the new one ended up tied to.
  String? _tiedTo;

  void _go(PracticeStep next) {
    if (guideMoves(context)) {
      next == PracticeStep.done
          ? HapticFeedback.mediumImpact()
          : HapticFeedback.selectionClick();
    }
    setState(() => step = next);
    widget.onStep?.call(next);
  }

  /// Does the current step, for those who cannot make the gesture.
  void skipStep() {
    switch (step) {
      case PracticeStep.add:
        _go(PracticeStep.move);
      case PracticeStep.move:
        _free = null;
        _go(PracticeStep.tie);
      case PracticeStep.tie:
        _tiedTo = 'day';
        _go(PracticeStep.done);
      case PracticeStep.done:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final night = isNight(context);
    final cork = walls.firstWhere((w) => w.id == 'cork');
    return LayoutBuilder(
      builder: (context, box) {
        final layout = _Layout(box.biggest, widget.top, widget.bottom);
        final (targets, label) = switch (step) {
          PracticeStep.add => ([_addKey], l10n.guideLitAdd),
          PracticeStep.move => ([_newKey, _spotKey], l10n.guideLitMove),
          PracticeStep.tie => ([_newKey, _dayKey], l10n.guideLitTie),
          PracticeStep.done => (<GlobalKey>[], null),
        };
        final task = switch (step) {
          PracticeStep.add => l10n.guideTaskAdd,
          PracticeStep.move => l10n.guideTaskMove,
          PracticeStep.tie => l10n.guideTaskTie,
          PracticeStep.done => null,
        };
        final still = widget.still != null;
        final placed = step.index > PracticeStep.move.index;
        final newAt = _free ?? (placed ? layout.spot : layout.start);
        final slide = guideMoves(context) && !_dragging
            ? const Duration(milliseconds: 420)
            : Duration.zero;
        return Stack(
          key: _stage,
          fit: StackFit.expand,
          children: [
            LitWindow(
              focus: step,
              targets: targets,
              label: label,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  WallBackground(
                    wall: night ? cork.atNight : cork,
                    decor: false,
                  ),
                  // The spot the new note is to be moved to.
                  if (step != PracticeStep.add)
                    Positioned(
                      left: layout.spot.dx,
                      top: layout.spot.dy + 14,
                      width: layout.card,
                      height: layout.card * .72,
                      child: AnimatedOpacity(
                        duration: slide,
                        opacity: placed ? 0 : 1,
                        child: _Spot(key: _spotKey, label: l10n.guideSpot),
                      ),
                    ),
                  _note(
                    layout,
                    at: layout.mum,
                    key: _mumKey,
                    id: 'mum',
                    words: l10n.guideNoteMum,
                    paper: 1,
                  ),
                  _note(
                    layout,
                    at: layout.day,
                    key: _dayKey,
                    id: 'day',
                    words: l10n.guideNoteSaturday,
                    paper: 2,
                  ),
                  if (step != PracticeStep.add)
                    AnimatedPositioned(
                      duration: slide,
                      curve: Curves.easeOutCubic,
                      left: newAt.dx,
                      top: newAt.dy,
                      width: layout.card,
                      child: _NewNote(
                        key: _newKey,
                        child: GestureDetector(
                          key: const Key('guide-practice-note'),
                          behavior: HitTestBehavior.opaque,
                          onPanStart: step == PracticeStep.move
                              ? (_) => setState(() {
                                  _dragging = true;
                                  _free = newAt;
                                })
                              : null,
                          onPanUpdate: step == PracticeStep.move
                              ? (d) => setState(
                                  () => _free = _clamp(
                                    (_free ?? newAt) + d.delta,
                                    layout,
                                  ),
                                )
                              : null,
                          onPanEnd: step == PracticeStep.move
                              ? (_) => _drop(layout)
                              : null,
                          child: _card(
                            id: 'new',
                            words: l10n.guideNoteWater,
                            paper: 0,
                            raised: _dragging,
                            cb: step == PracticeStep.tie
                                ? _pinPull(layout)
                                : _still,
                          ),
                        ),
                      ),
                    ),
                  // Threads: the one tied, and the one being pulled.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ThreadsPainter(
                          from: _pinOf(newAt, layout),
                          to: switch (_tiedTo) {
                            'day' => _pinOf(layout.day, layout),
                            'mum' => _pinOf(layout.mum, layout),
                            _ when still && step == PracticeStep.tie =>
                              Offset.lerp(
                                _pinOf(newAt, layout),
                                _pinOf(layout.day, layout),
                                .7,
                              ),
                            _ => _pull,
                          },
                          tied: _tiedTo != null,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: widget.bottom + 24,
                    child: KeyedSubtree(
                      key: _addKey,
                      child: AddNoteButton(
                        key: const Key('guide-practice-add'),
                        label: l10n.addToWall,
                        extended: false,
                        onPressed: () {
                          if (step == PracticeStep.add) _go(PracticeStep.move);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // What is on screen, lit above the dark.
            if (task != null && !still)
              Positioned(
                top: widget.top + 8,
                left: 16,
                right: 16,
                child: IgnorePointer(
                  child: Center(
                    child: _TaskLine(key: ValueKey(step), text: task),
                  ),
                ),
              ),
            // For anyone who cannot make the gesture: do the step.
            if (step != PracticeStep.done && !still)
              Positioned(
                left: 8,
                bottom: widget.bottom + 20,
                child: TextButton(
                  key: const Key('guide-practice-next'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.chalk,
                    minimumSize: const Size(64, AppMetrics.target),
                    textStyle: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: skipStep,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.guideNext),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: AppColors.chalk,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Offset _clamp(Offset at, _Layout layout) => Offset(
    at.dx.clamp(0, math.max(0, layout.size.width - layout.card)),
    at.dy.clamp(widget.top, math.max(widget.top, layout.size.height - 120)),
  );

  /// Let go: on (or near) the spot, the note settles there.
  void _drop(_Layout layout) {
    final at = _free;
    setState(() => _dragging = false);
    if (at == null) return;
    if ((at - layout.spot).distance < layout.card * .6) {
      _free = null;
      _go(PracticeStep.tie);
    }
  }

  /// The new note's pin, which a thread can be pulled out of.
  NoteCallbacks _pinPull(_Layout layout) => NoteCallbacks(
    onEdit: () {},
    onTogglePin: () {},
    onToggleItem: (_) {},
    onLongPress: () {},
    onPinDragStart: (g) => setState(() => _pull = _local(g)),
    onPinDragUpdate: (g) => setState(() => _pull = _local(g)),
    onPinDragEnd: (g) {
      final end = g == Offset.zero ? null : _local(g);
      final onto = end == null ? null : _noteAt(end);
      setState(() => _pull = null);
      if (onto != null) {
        _tiedTo = onto;
        _go(PracticeStep.done);
      }
    },
  );

  Offset _local(Offset global) {
    final box = _stage.currentContext?.findRenderObject();
    return box is RenderBox ? box.globalToLocal(global) : global;
  }

  /// Which other note is under [local], generously.
  String? _noteAt(Offset local) {
    for (final (id, key) in [('day', _dayKey), ('mum', _mumKey)]) {
      final box = key.currentContext?.findRenderObject();
      final stage = _stage.currentContext?.findRenderObject();
      if (box is! RenderBox || stage is! RenderBox || !box.hasSize) continue;
      final r = box.localToGlobal(Offset.zero, ancestor: stage) & box.size;
      if (r.inflate(16).contains(local)) return id;
    }
    return null;
  }

  Offset _pinOf(Offset topLeft, _Layout layout) =>
      topLeft + Offset(layout.card / 2, 14);

  Widget _note(
    _Layout layout, {
    required Offset at,
    required GlobalKey key,
    required String id,
    required String words,
    required int paper,
  }) => Positioned(
    left: at.dx,
    top: at.dy,
    width: layout.card,
    child: KeyedSubtree(
      key: key,
      child: _card(id: id, words: words, paper: paper, cb: _still),
    ),
  );

  Widget _card({
    required String id,
    required String words,
    required int paper,
    required NoteCallbacks cb,
    bool raised = false,
  }) => ExcludeSemantics(
    child: ExcludeFocus(
      child: StickyNoteCard(
        note: Note(
          guid: 'guide-practice-$id',
          content: words,
          createdAt: DateTime(2026),
          boardId: '',
          colorIndex: paper,
        ),
        cb: cb,
        raised: raised,
        maxContentLines: 3,
      ),
    ),
  );
}

/// Callbacks for notes that only sit there.
final _still = NoteCallbacks(
  onEdit: () {},
  onTogglePin: () {},
  onToggleItem: (_) {},
  onLongPress: () {},
);

/// Where things go on a practice wall of [size]: two notes at the top, the
/// new one appearing on the left, the spot it moves to on the right, the
/// yellow paper at the bottom right.
class _Layout {
  _Layout(this.size, double top, double bottom)
    : card = math.min(140, (size.width - 56) / 2) {
    final area = Rect.fromLTRB(
      20,
      top + 64,
      size.width - 20,
      math.max(top + 64 + 300, size.height - bottom - 110),
    );
    final h = area.height;
    mum = Offset(area.left, area.top + h * .02);
    day = Offset(area.right - card, area.top + h * .08);
    start = Offset(area.left + 6, area.top + h * .5);
    spot = Offset(area.right - card, area.top + h * .58);
  }

  final Size size;
  final double card;
  late final Offset mum;
  late final Offset day;
  late final Offset start;
  late final Offset spot;
}

/// The new note pops onto the wall with a bounce.
class _NewNote extends StatelessWidget {
  const _NewNote({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: guideMoves(context)
        ? const Duration(milliseconds: 520)
        : Duration.zero,
    curve: Curves.easeOutBack,
    builder: (context, t, child) => Transform.scale(
      scale: .4 + .6 * t,
      child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
    ),
    child: child,
  );
}

/// The marked spot: a dashed outline with a word in it.
class _Spot extends StatelessWidget {
  const _Spot({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _DashedBox(),
    child: Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.chalk,
          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
      ),
    ),
  );
}

class _DashedBox extends CustomPainter {
  const _DashedBox();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadii.control),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0x33FDFBF3));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = AppColors.chalk;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 14) {
        canvas.drawPath(metric.extractPath(d, d + 8), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBox old) => false;
}

class _ThreadsPainter extends CustomPainter {
  const _ThreadsPainter({
    required this.from,
    required this.to,
    required this.tied,
  });

  final Offset from;
  final Offset? to;
  final bool tied;

  @override
  void paint(Canvas canvas, Size size) {
    final end = to;
    if (end == null) return;
    paintGuideYarn(canvas, from, end);
  }

  @override
  bool shouldRepaint(_ThreadsPainter old) =>
      old.from != from || old.to != to || old.tied != tied;
}

/// The line at the top saying what is on screen: a dark pill above the
/// dark, read out when it changes.
class _TaskLine extends StatelessWidget {
  const _TaskLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    header: true,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.overlayDark,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x40FDFBF3)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: AppColors.chalk,
        ),
      ),
    ),
  );
}
