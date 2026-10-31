part of 'wall_view.dart';

// The wall's pieces that hold no state of the wall itself: the lasso,
// the drop tray, threads and their painter, the gesture recognizers and
// the resize / rotate grips.

/// The loop drawn round notes in select mode.
class _LassoPainter extends CustomPainter {
  const _LassoPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path..close(),
      Paint()..color = AppColors.accent.withValues(alpha: 0.14),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke..color = const Color(0x66000000));
    canvas.drawPath(
      path,
      stroke
        ..color = AppColors.accent
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_LassoPainter old) =>
      old.points.length != points.length ||
      (points.isNotEmpty && old.points.last != points.last);
}

/// The tray a dragged note can be dropped into to delete it. Slides in from
/// below the wall while a drag is under way and turns red under the finger.
class _DropTray extends StatelessWidget {
  const _DropTray({
    super.key,
    required this.shown,
    required this.armed,
    required this.label,
  });

  final bool shown;
  final bool armed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSlide(
        offset: shown ? Offset.zero : const Offset(0, 1.4),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: AnimatedScale(
            scale: armed ? 1.04 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: armed ? AppColors.deleteIcon : AppColors.overlayDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.chalk.withValues(alpha: armed ? 0.9 : 0.4),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    armed ? Icons.delete : Icons.delete_outline,
                    color: Colors.white,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One piece of yarn between two points on the wall.
class _Thread {
  const _Thread(
    this.a,
    this.b, {
    this.link,
    this.live = false,
    this.faded = false,
  });

  final Offset a;
  final Offset b;
  final NoteLink? link;

  /// Being dragged right now (end follows the finger).
  final bool live;

  /// One end is a dimmed (filtered-out) note.
  final bool faded;

  /// Yarn sags a little between the pins, more the longer it is.
  Offset get control {
    final mid = (a + b) / 2;
    final sag = math.min(30.0, (a - b).distance * 0.12);
    return mid + Offset(0, sag);
  }

  Path get path => Path()
    ..moveTo(a.dx, a.dy)
    ..quadraticBezierTo(control.dx, control.dy, b.dx, b.dy);

  /// The yarn's colour: the link's own, or the classic red.
  Color get color => Color(link?.color ?? AppColors.yarns.first);

  /// The point a fraction [t] along the curve.
  Offset pointAt(double t) {
    final c = control;
    return a * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + b * (t * t);
  }

  /// Distance from [p] to the curve, sampled — plenty for a fingertip.
  double distanceTo(Offset p) {
    var best = double.infinity;
    final c = control;
    for (var i = 0; i <= 24; i++) {
      final t = i / 24;
      final q = a * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + b * (t * t);
      best = math.min(best, (q - p).distance);
    }
    return best;
  }
}

/// Draws the threads tied between pins, sagging slightly like real string,
/// each in its own yarn colour, with an arrowhead and a paper tag where the
/// link asks for them — plus the one currently being dragged out.
class _ThreadPainter extends CustomPainter {
  const _ThreadPainter(
    this.threads, {
    this.highlight = false,
    this.tagStyle = const TextStyle(),
  });

  final List<_Thread> threads;
  final bool highlight;

  /// Style for the words on a tag — the app's own face, sized down.
  final TextStyle tagStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final yarn = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final sheen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x66FFFFFF);

    for (final t in threads) {
      final path = t.path;
      final alpha = t.faded ? 0.3 : (t.live && !highlight ? 0.75 : 1.0);
      final color = t.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(1.5, 2.5);
      canvas.drawPath(
        path,
        shadow..color = Color.fromRGBO(0, 0, 0, 0.33 * alpha),
      );
      canvas.restore();
      canvas.drawPath(path, yarn..color = color);
      canvas.save();
      canvas.translate(0, -0.6);
      canvas.drawPath(
        path,
        sheen..color = Color.fromRGBO(255, 255, 255, 0.4 * alpha),
      );
      canvas.restore();
      // Little knot where the yarn is wound round each pin.
      final knot = Paint()..color = color;
      canvas.drawCircle(t.a, 3.2, knot);
      if (!t.live) canvas.drawCircle(t.b, 3.2, knot);

      final link = t.link;
      if (link == null) continue;
      if (link.arrow) _arrowhead(canvas, t, knot);
      if (link.label.isNotEmpty) _tag(canvas, t, alpha);
    }
  }

  /// A small filled head just short of the [b] knot, along the yarn.
  void _arrowhead(Canvas canvas, _Thread t, Paint paint) {
    final tip = t.b;
    final back = t.pointAt(0.9);
    final dir = tip - back;
    if (dir.distance < 1) return;
    final u = dir / dir.distance;
    final n = Offset(-u.dy, u.dx);
    final base = tip - u * 13;
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + n.dx * 5.5, base.dy + n.dy * 5.5)
      ..lineTo(base.dx - n.dx * 5.5, base.dy - n.dy * 5.5)
      ..close();
    canvas.drawPath(head, paint);
  }

  /// A paper tag hung from the middle of the thread, with the label on it.
  void _tag(Canvas canvas, _Thread t, double alpha) {
    final text = TextPainter(
      text: TextSpan(
        text: t.link!.label,
        style: tagStyle.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.ink.withValues(alpha: alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 120);
    final mid = t.pointAt(0.5);
    final rect = Rect.fromCenter(
      center: mid + const Offset(0, 6),
      width: text.width + 14,
      height: text.height + 7,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(
      rrect.shift(const Offset(1, 2)),
      Paint()..color = Color.fromRGBO(0, 0, 0, 0.25 * alpha),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = AppColors.paper.withValues(alpha: alpha),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = t.color.withValues(alpha: 0.6 * alpha),
    );
    text.paint(canvas, Offset(rect.left + 7, rect.top + 3.5));
    text.dispose();
  }

  @override
  bool hitTest(Offset position) {
    for (final t in threads) {
      if (t.link != null && t.distanceTo(position) <= 14) return true;
    }
    return false;
  }

  @override
  bool shouldRepaint(_ThreadPainter old) =>
      old.highlight != highlight ||
      old.threads.length != threads.length ||
      !_sameEnds(old.threads, threads);

  static bool _sameEnds(List<_Thread> x, List<_Thread> y) {
    for (var i = 0; i < x.length; i++) {
      final p = x[i];
      final q = y[i];
      if (p.a != q.a ||
          p.b != q.b ||
          p.faded != q.faded ||
          p.link?.color != q.link?.color ||
          p.link?.label != q.link?.label ||
          p.link?.arrow != q.link?.arrow) {
        return false;
      }
    }
    return true;
  }
}

/// The gesture on a note: one finger drags it, two turn and resize it. A
/// stock [ScaleGestureRecognizer] only claims the gesture once the fingers
/// have moved apart or their midpoint has travelled the pan slop — a clean
/// twist does neither, so it would never begin. Two fingers on one card can
/// mean nothing else, so this claims them the moment the second one lands
/// (a lone finger still waits for the slop, leaving taps and long-presses
/// to the card).
class _NoteGestureRecognizer extends ScaleGestureRecognizer {
  Offset? _down;
  bool _claimed = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _down ??= event.position;
  }

  @override
  void handleEvent(PointerEvent event) {
    // Claim a one-finger drag a little before the wall's own pan would: the
    // InteractiveViewer behind the note competes for the same finger, and
    // whichever recognizer crosses its slop first takes the gesture. A
    // finger that moves on a card means "drag the card".
    final down = _down;
    if (!_claimed &&
        event is PointerMoveEvent &&
        down != null &&
        pointerCount == 1 &&
        (event.position - down).distance >
            0.8 * computePanSlop(event.kind, gestureSettings)) {
      _claimed = true;
      resolve(GestureDisposition.accepted);
    }
    super.handleEvent(event);
    if (event is PointerDownEvent && pointerCount >= 2) {
      _claimed = true;
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _down = null;
    _claimed = false;
    super.didStopTrackingLastPointer(pointer);
  }
}

/// The drag of a corner grip. A plain pan waits for the finger to travel the
/// pan slop (36px) before it counts, and a grip that far behind the finger
/// feels stuck — this one takes the gesture after a few pixels, since there is
/// nothing else a drag on a grip could mean. Positions are measured from
/// where the finger landed, so a turn loses none of its first degrees.
class _GripDragRecognizer extends PanGestureRecognizer {
  _GripDragRecognizer() {
    dragStartBehavior = DragStartBehavior.down;
  }

  static const double _slop = 6;

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) => globalDistanceMoved.abs() > _slop;
}

/// A corner grip — the resize handle at bottom-right, the rotate handle at
/// bottom-left. Hidden until its note is the active one, so the wall reads as
/// paper on texture rather than a field of dark buttons.
class _Grip extends StatelessWidget {
  const _Grip({
    required this.visible,
    required this.engaged,
    required this.icon,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.onTap,
    this.tooltip,
  });

  final bool visible;

  /// Being dragged right now: drawn bigger and darker.
  final bool engaged;
  final IconData icon;
  final void Function(DragStartDetails details) onPanStart;
  final void Function(DragUpdateDetails details) onPanUpdate;
  final VoidCallback onPanEnd;
  final VoidCallback? onTap;
  final String? tooltip;

  /// Transparent room around the disc that still takes the finger: the
  /// disc is 26dp, the target 44dp.
  static const margin = 9.0;

  @override
  Widget build(BuildContext context) {
    final size = engaged ? 30.0 : 26.0;
    Widget grip = RawGestureDetector(
      gestures: {
        if (onTap != null)
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (r) => r.onTap = onTap,
              ),
        _GripDragRecognizer:
            GestureRecognizerFactoryWithHandlers<_GripDragRecognizer>(
              _GripDragRecognizer.new,
              (r) {
                r.gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
                r.onStart = onPanStart;
                r.onUpdate = onPanUpdate;
                r.onEnd = (_) => onPanEnd();
                r.onCancel = onPanEnd;
              },
            ),
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(margin + (26 - size) / 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: engaged ? AppColors.ink : AppColors.overlayDark,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.chalk, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 13, color: Colors.white),
        ),
      ),
    );
    if (tooltip != null) grip = Tooltip(message: tooltip, child: grip);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedScale(
        scale: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: grip,
      ),
    );
  }
}
