import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/note.dart';
import '../theme.dart';
import '../widgets/thread_style.dart';

/// Whether this person allows movement (the system's reduce-motion
/// setting). Without it every part of the guide is simply at rest.
bool guideMoves(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) != true;

/// The guide's handwriting size for titles, balanced like the notes are.
double guideTitleSize(BuildContext context, {required bool wide}) =>
    (wide ? 46.0 : 36.0) * noteFontScale(context);

/// The guide's warm ground: the app's paper, dimmed with the lights off.
Color guideGround(BuildContext context) =>
    Theme.of(context).colorScheme.surface;

/// One stage's clock (0 → 1), shared by everything on the stage through
/// [GuideBeat.of], so the parts arrive in order: title, highlight, words,
/// then the button.
class GuideBeat extends InheritedNotifier<Animation<double>> {
  const GuideBeat({
    super.key,
    required Animation<double> clock,
    required super.child,
  }) : super(notifier: clock);

  static Animation<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GuideBeat>()?.notifier ??
      const AlwaysStoppedAnimation(1);
}

/// The fraction [from]–[to] of the stage's clock, eased: 0 before, 1 after.
double guideSlice(double clock, double from, double to) =>
    ((clock - from) / (to - from)).clamp(0.0, 1.0);

/// Arrives during [from]–[to] of the stage's clock: fades in and rises
/// [rise] px (growing from [scale]) with a soft overshoot.
class GuideReveal extends StatelessWidget {
  const GuideReveal({
    super.key,
    this.from = 0,
    this.to = .45,
    this.rise = 18,
    this.scale = 1,
    required this.child,
  });

  final double from;
  final double to;
  final double rise;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clock = GuideBeat.of(context);
    return AnimatedBuilder(
      animation: clock,
      builder: (context, child) {
        final raw = guideSlice(clock.value, from, to);
        final t = Curves.easeOutBack.transform(raw);
        return Opacity(
          opacity: Curves.easeOut.transform(raw),
          child: Transform.translate(
            offset: Offset(0, rise * (1 - t)),
            child: Transform.scale(
              scale: scale + (1 - scale) * t,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// A stage title in the handwriting face, with a band of highlighter drawn
/// in under its key [words] during [from]–[to] of the stage's clock. Read
/// as one header by a screen reader.
class GuideTitle extends StatelessWidget {
  const GuideTitle({
    super.key,
    required this.before,
    required this.words,
    this.after = '',
    required this.style,
    this.textAlign = TextAlign.start,
    this.from = .3,
    this.to = .7,
  });

  final String before;
  final String words;
  final String after;
  final TextStyle style;
  final TextAlign textAlign;
  final double from;
  final double to;

  @override
  Widget build(BuildContext context) {
    final clock = GuideBeat.of(context);
    final band = isNight(context)
        ? nightPaper(AppColors.accent).withValues(alpha: .75)
        : AppColors.accent.withValues(alpha: .62);
    return Semantics(
      header: true,
      label: '$before$words$after'.replaceAll('\n', ' '),
      excludeSemantics: true,
      child: Text.rich(
        textAlign: textAlign,
        TextSpan(
          style: style,
          children: [
            TextSpan(text: before),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: AnimatedBuilder(
                animation: clock,
                builder: (context, child) => CustomPaint(
                  painter: _Band(
                    Curves.easeInOutCubic.transform(
                      guideSlice(clock.value, from, to),
                    ),
                    band,
                  ),
                  child: child,
                ),
                // The paragraph scales its inline widgets by the reader's
                // text size already; scaling here too would double it.
                child: Text(
                  '$words$after',
                  style: style,
                  textScaler: TextScaler.noScaling,
                  textAlign: textAlign,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A highlighter stroke under the key words, drawn left to right.
class _Band extends CustomPainter {
  const _Band(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final h = size.height * .36;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -3,
          size.height - h - size.height * .1,
          (size.width + 6) * t,
          h,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_Band old) => old.t != t || old.color != color;
}

/// Darkens everything except the thing to do next, which sits in a lit
/// window: a warm glow spilling out of it, a crisp edge and a ring that
/// breathes a few times (then rests, so nothing moves for long). A label
/// beside it says what to do. When [focus] changes the window glides to the
/// new [targets]; with no targets the dark lifts. Touches pass through
/// everywhere: the scene underneath decides what reacts.
class LitWindow extends StatefulWidget {
  const LitWindow({
    super.key,
    required this.focus,
    required this.targets,
    this.label,
    this.labelBelow,
    required this.child,
  });

  /// What is lit now; a change glides the window.
  final Object? focus;

  /// The widgets to light; the window spans all of them.
  final List<GlobalKey> targets;
  final String? label;

  /// Where the label goes; by default below a target in the top half and
  /// above one in the bottom half.
  final bool? labelBelow;
  final Widget child;

  @override
  State<LitWindow> createState() => _LitWindowState();
}

class _LitWindowState extends State<LitWindow> with TickerProviderStateMixin {
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..addListener(_track);

  /// The breathing ring: three slow breaths, then still.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  Rect? _from;
  Rect? _at;
  bool _fadeIn = true;
  bool _fadeOut = false;
  int _breaths = 0;

  @override
  void initState() {
    super.initState();
    _glow.addStatusListener((s) {
      if (s != AnimationStatus.completed) return;
      _breaths++;
      if (_breaths < 3 && mounted) _glow.forward(from: 0);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_move.value == 0 && !_move.isAnimating) _start();
  }

  @override
  void didUpdateWidget(LitWindow old) {
    super.didUpdateWidget(old);
    if (old.focus != widget.focus) {
      _from = _shown;
      _fadeIn = old.targets.isEmpty;
      _fadeOut = widget.targets.isEmpty;
      _start();
    }
  }

  void _start() {
    if (guideMoves(context)) {
      _move.forward(from: 0);
    } else {
      _move.value = 1;
    }
    _breaths = 0;
    if (widget.targets.isNotEmpty && guideMoves(context)) {
      _glow.forward(from: 0);
    } else {
      _glow
        ..stop()
        ..value = 0;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _track());
  }

  /// Where the targets are now, in this widget's own coordinates.
  void _track() {
    if (!mounted || widget.targets.isEmpty) return;
    final me = context.findRenderObject();
    if (me is! RenderBox || !me.hasSize) return;
    Rect? span;
    for (final key in widget.targets) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final r = box.localToGlobal(Offset.zero, ancestor: me) & box.size;
      span = span == null ? r : span.expandToInclude(r);
    }
    if (span != null && span != _at) setState(() => _at = span);
  }

  double get _t => Curves.easeInOutCubic.transform(_move.value);

  Rect? get _shown {
    if (_fadeOut) return _from;
    if (_from == null || _at == null) return _at;
    return Rect.lerp(_from, _at, _t);
  }

  double get _dark => _fadeOut ? 1 - _t : (_fadeIn ? _t : 1);

  @override
  void dispose() {
    _move.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _track());
    final still = !guideMoves(context);
    return LayoutBuilder(
      builder: (context, box) => Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_move, _glow]),
              builder: (context, _) => CustomPaint(
                painter: _WindowPainter(
                  hole: _shown,
                  dark: _dark,
                  glow: _glow.value,
                  still: still || _breaths >= 3,
                ),
              ),
            ),
          ),
          if (widget.label != null)
            AnimatedBuilder(
              animation: _move,
              builder: (context, _) {
                final hole = _shown;
                if (hole == null || _fadeOut) return const SizedBox.shrink();
                return Stack(
                  fit: StackFit.expand,
                  children: [_label(box.biggest, hole)],
                );
              },
            ),
        ],
      ),
    );
  }

  /// The words beside the window, kept on screen.
  Widget _label(Size size, Rect hole) {
    final below = widget.labelBelow ?? hole.center.dy < size.height / 2;
    final x = (hole.center.dx / size.width * 2 - 1).clamp(-1.0, 1.0);
    final pill = IgnorePointer(
      child: Opacity(
        opacity: Curves.easeOut.transform(guideSlice(_move.value, .55, 1)),
        child: Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.chalk,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x80FFCA28),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  below ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 18,
                  color: AppColors.ink,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label!,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Positioned(
      left: 12,
      right: 12,
      top: below ? hole.bottom + 20 : null,
      bottom: below ? null : size.height - hole.top + 20,
      child: Align(alignment: Alignment(x, 0), child: pill),
    );
  }
}

class _WindowPainter extends CustomPainter {
  const _WindowPainter({
    required this.hole,
    required this.dark,
    required this.glow,
    required this.still,
  });

  final Rect? hole;
  final double dark;
  final double glow;
  final bool still;

  /// Lamp light: the app's sunny accent.
  static const _light = AppColors.accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (dark <= 0) return;
    final a = dark.clamp(0.0, 1.0);
    final scrim = Paint()..color = Color.fromRGBO(18, 12, 6, .74 * a);
    final full = Offset.zero & size;
    if (hole == null) {
      canvas.drawRect(full, scrim);
      return;
    }
    final window = RRect.fromRectAndRadius(
      hole!.inflate(10),
      const Radius.circular(18),
    );
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(full)
        ..addRRect(window),
      scrim,
    );
    // The light: a soft glow spilling out of the window, then a crisp edge.
    canvas.drawRRect(
      window.inflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..color = _light.withValues(alpha: .8 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawRRect(
      window,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.chalk.withValues(alpha: a),
    );
    if (still) return;
    final g = Curves.easeOut.transform(glow);
    canvas.drawRRect(
      window.inflate(3 + 18 * g),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - g)
        ..color = _light.withValues(alpha: (1 - g) * .9 * a),
    );
  }

  @override
  bool shouldRepaint(_WindowPainter old) =>
      old.hole != hole ||
      old.dark != dark ||
      old.glow != glow ||
      old.still != still;
}

/// The practice's success mark: a sunny disc with an ink tick that pops in
/// with a bounce and sends out one ring. At rest under reduce motion.
class GuideCheck extends StatefulWidget {
  const GuideCheck({super.key, this.size = 64, this.label});

  final double size;

  /// Announced to a screen reader when the check appears.
  final String? label;

  @override
  State<GuideCheck> createState() => _GuideCheckState();
}

class _GuideCheckState extends State<GuideCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pop.value > 0 || _pop.isAnimating) return;
    guideMoves(context) ? _pop.forward() : _pop.value = 1;
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disc = isNight(context)
        ? nightPaper(AppColors.accent)
        : AppColors.accent;
    final s = widget.size;
    return Semantics(
      liveRegion: widget.label != null,
      label: widget.label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: s * 1.6,
        child: AnimatedBuilder(
          animation: _pop,
          builder: (context, _) {
            final grow = Curves.elasticOut.transform(
              guideSlice(_pop.value, 0, .85),
            );
            final ring = Curves.easeOut.transform(
              guideSlice(_pop.value, .15, 1),
            );
            return CustomPaint(
              painter: _RingPainter(
                t: ring,
                color: disc,
                radius: s / 2,
                show: _pop.value < 1,
              ),
              child: Center(
                child: Transform.scale(
                  scale: grow,
                  child: Container(
                    width: s,
                    height: s,
                    decoration: BoxDecoration(
                      color: disc,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40302318),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: s * .6,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.t,
    required this.color,
    required this.radius,
    required this.show,
  });

  final double t;
  final Color color;
  final double radius;
  final bool show;

  @override
  void paint(Canvas canvas, Size size) {
    if (!show || t <= 0) return;
    canvas.drawCircle(
      size.center(Offset.zero),
      radius + radius * .6 * t,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * (1 - t)
        ..color = color.withValues(alpha: 1 - t),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.t != t || old.color != color || old.show != show;
}

/// A piece of red yarn tied between two pins, sagging like string, as the
/// wall draws its threads. Only the first [progress] of it is drawn, so it
/// can be strung across.
void paintGuideYarn(
  Canvas canvas,
  Offset a,
  Offset b, {
  double progress = 1,
  Color color = const Color(0xFFC62828),
}) {
  if (progress <= 0) return;
  final mid = (a + b) / 2;
  final sag = math.min(30.0, (a - b).distance * .12);
  final c = mid + Offset(0, sag);
  final full = Path()
    ..moveTo(a.dx, a.dy)
    ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy);
  var path = full;
  if (progress < 1) {
    final metric = full.computeMetrics().first;
    path = metric.extractPath(0, metric.length * progress);
  }
  canvas
    ..save()
    ..translate(1.5, 2.5)
    ..drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    )
    ..restore();
  paintThreadLine(canvas, path, color, ThreadStyle.yarn);
  final knot = Paint()..color = color;
  canvas.drawCircle(a, 3.2, knot);
  if (progress >= 1) canvas.drawCircle(b, 3.2, knot);
}
