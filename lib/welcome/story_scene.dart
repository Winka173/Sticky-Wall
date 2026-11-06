import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../theme.dart';
import '../widgets/note_views.dart';
import '../widgets/wall_background.dart';
import 'guide_motion.dart';

/// The story's two beats in one picture, so the papers really travel:
/// scraps of paper scattered and greying ([gathered] false), then the same
/// scraps flown onto a cork wall as pinned sticky notes, two of them tied by
/// a thread ([gathered] true). Drawn on a 400 × 560 canvas, scaled to fit.
/// A picture only: hidden from screen readers and from the keyboard.
class StoryScene extends StatelessWidget {
  const StoryScene({super.key, required this.gathered});

  final bool gathered;

  static const _w = 400.0;
  static const _h = 560.0;
  static const _card = 150.0;

  // Where each paper rests (left, top, turn): scattered, then on the wall.
  // The phone and the napkin swap sides on the way, so they cross.
  static const _scattered = [
    (12.0, 34.0, -.13),
    (222.0, 62.0, .11),
    (34.0, 300.0, .07),
    (214.0, 322.0, -.09),
  ];
  static const _gathered = [
    (30.0, 74.0, -.035),
    (218.0, 62.0, .04),
    (214.0, 316.0, .03),
    (32.0, 304.0, -.03),
  ];

  /// The two notes the yarn ties: the birthday and the flowers.
  static const _tied = (1, 3);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final moves = guideMoves(context);
    final time = moves ? const Duration(milliseconds: 780) : Duration.zero;
    final words = [
      l10n.guideScrapPlumber,
      l10n.guideScrapBirthday,
      l10n.guideScrapWifi,
      l10n.guideScrapFlowers,
    ];
    // Papers in the app's own colours: mint, pink, blue, yellow.
    const papers = [2, 1, 3, 0];
    final night = isNight(context);
    final cork = walls.firstWhere((w) => w.id == 'cork');
    return ExcludeSemantics(
      child: ExcludeFocus(
        child: IgnorePointer(
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.noScaling),
            child: FittedBox(
              child: SizedBox(
                width: _w,
                height: _h,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // The wall the scraps are pinned to.
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: time,
                        opacity: gathered ? 1 : 0,
                        child: AnimatedScale(
                          duration: time,
                          curve: Curves.easeOutBack,
                          scale: gathered ? 1 : .9,
                          child: _CorkPanel(wall: night ? cork.atNight : cork),
                        ),
                      ),
                    ),
                    for (var i = 0; i < words.length; i++)
                      AnimatedPositioned(
                        key: ValueKey('paper-$i'),
                        duration: time,
                        curve: Curves.easeOutBack,
                        left: (gathered ? _gathered : _scattered)[i].$1,
                        top: (gathered ? _gathered : _scattered)[i].$2,
                        child: AnimatedRotation(
                          duration: time,
                          curve: Curves.easeOut,
                          turns:
                              (gathered ? _gathered : _scattered)[i].$3 /
                              (2 * math.pi),
                          child: AnimatedSwitcher(
                            duration: moves
                                ? const Duration(milliseconds: 420)
                                : Duration.zero,
                            child: gathered
                                ? SizedBox(
                                    key: const ValueKey('note'),
                                    width: _card,
                                    child: _note(i, words[i], papers[i]),
                                  )
                                : GuideReveal(
                                    key: const ValueKey('scrap'),
                                    from: i * .08,
                                    to: .32 + i * .08,
                                    rise: 70,
                                    scale: .7,
                                    child: _Lost(child: _scrap(i, words[i])),
                                  ),
                          ),
                        ),
                      ),
                    if (gathered)
                      Positioned.fill(
                        child: _Yarn(
                          a: _pin(_gathered[_tied.$1]),
                          b: _pin(_gathered[_tied.$2]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Offset _pin((double, double, double) at) =>
      Offset(at.$1 + _card / 2, at.$2 + 14);

  Widget _note(int i, String words, int paper) => StickyNoteCard(
    note: Note(
      guid: 'guide-story-$i',
      content: words,
      createdAt: DateTime(2026),
      boardId: '',
      colorIndex: paper,
    ),
    cb: _still,
    rotated: false,
    maxContentLines: 3,
  );

  Widget _scrap(int i, String words) => switch (i) {
    0 => _Receipt(words),
    1 => _TornSticky(words),
    2 => _PhoneNote(words),
    _ => _Napkin(words),
  };
}

/// Callbacks for pictures of cards: nothing happens.
final _still = NoteCallbacks(
  onEdit: () {},
  onTogglePin: () {},
  onToggleItem: (_) {},
  onLongPress: () {},
);

/// A cork board the size of the canvas, with a soft shadow.
class _CorkPanel extends StatelessWidget {
  const _CorkPanel({required this.wall});

  final WallStyle wall;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40302318),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: WallBackground(wall: wall, decor: false),
    ),
  );
}

/// The yarn strung between two pins once the notes have landed.
class _Yarn extends StatelessWidget {
  const _Yarn({required this.a, required this.b});

  final Offset a;
  final Offset b;

  @override
  Widget build(BuildContext context) {
    final clock = GuideBeat.of(context);
    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) => CustomPaint(
        painter: _YarnPainter(
          a,
          b,
          Curves.easeInOut.transform(guideSlice(clock.value, .55, .9)),
        ),
      ),
    );
  }
}

class _YarnPainter extends CustomPainter {
  const _YarnPainter(this.a, this.b, this.t);

  final Offset a;
  final Offset b;
  final double t;

  @override
  void paint(Canvas canvas, Size size) =>
      paintGuideYarn(canvas, a, b, progress: t);

  @override
  bool shouldRepaint(_YarnPainter old) => old.t != t;
}

/// Late in the first beat the scraps go grey: written down, then lost.
class _Lost extends StatelessWidget {
  const _Lost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clock = GuideBeat.of(context);
    return AnimatedBuilder(
      animation: clock,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(guideSlice(clock.value, .62, .92));
        return Opacity(
          opacity: 1 - .35 * t,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(_grey(t * .85)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static List<double> _grey(double t) {
    const g = [
      .33, .59, .11, 0, 0, //
      .33, .59, .11, 0, 0,
      .33, .59, .11, 0, 0,
      0, 0, 0, 1, 0,
    ];
    const id = [
      1, 0, 0, 0, 0, //
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];
    return [for (var i = 0; i < 20; i++) id[i] + (g[i] - id[i]) * t];
  }
}

/// Scribbled words on a scrap, in the handwriting face.
TextStyle _scribble(BuildContext context, {Color color = AppColors.ink}) =>
    TextStyle(fontSize: 19 * noteFontScale(context), height: 1.2, color: color);

Color _lit(BuildContext context, Color day) =>
    isNight(context) ? nightPaper(day) : day;

const _shade = [
  BoxShadow(color: Color(0x33302318), blurRadius: 8, offset: Offset(1, 4)),
];

/// A till receipt: printed lines, a zigzag tear, a note in biro.
class _Receipt extends StatelessWidget {
  const _Receipt(this.words);

  final String words;

  @override
  Widget build(BuildContext context) {
    Widget line(double w) => Container(
      width: w,
      height: 5,
      margin: const EdgeInsets.only(bottom: 7),
      color: const Color(0x30302318),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: _shade),
      child: ClipPath(
        clipper: const _ZigzagBottom(),
        child: Container(
          width: 150,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
          color: _lit(context, const Color(0xFFFBFAF4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: line(70)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [line(64), line(26)],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [line(48), line(26)],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [line(56), line(30)],
              ),
              const SizedBox(height: 6),
              Transform.rotate(
                angle: -.05,
                child: Text(
                  words,
                  style: _scribble(context, color: const Color(0xFF1E4FA8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZigzagBottom extends CustomClipper<Path> {
  const _ZigzagBottom();

  @override
  Path getClip(Size size) {
    const tooth = 10.0;
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - tooth);
    var x = size.width;
    var down = true;
    while (x > 0) {
      x = math.max(0, x - tooth);
      p.lineTo(x, down ? size.height : size.height - tooth);
      down = !down;
    }
    return p..close();
  }

  @override
  bool shouldReclip(_ZigzagBottom old) => false;
}

/// A sticky note torn off in a hurry: a ragged bottom edge.
class _TornSticky extends StatelessWidget {
  const _TornSticky(this.words);

  final String words;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(boxShadow: _shade),
    child: ClipPath(
      clipper: const _RaggedBottom(),
      child: Container(
        width: 140,
        padding: const EdgeInsets.fromLTRB(14, 18, 12, 30),
        color: _lit(context, AppColors.notePapers[0]),
        child: Text(words, style: _scribble(context)),
      ),
    ),
  );
}

class _RaggedBottom extends CustomClipper<Path> {
  const _RaggedBottom();

  @override
  Path getClip(Size size) {
    // A fixed tear, so it is the same on every frame.
    const dips = [6.0, 14.0, 4.0, 12.0, 2.0, 16.0, 7.0, 13.0, 3.0, 10.0];
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0);
    for (var i = 0; i <= dips.length; i++) {
      final x = size.width * (1 - i / dips.length);
      p.lineTo(x, size.height - dips[i % dips.length]);
    }
    return p..close();
  }

  @override
  bool shouldReclip(_RaggedBottom old) => false;
}

/// A phone with a note typed into it.
class _PhoneNote extends StatelessWidget {
  const _PhoneNote(this.words);

  final String words;

  @override
  Widget build(BuildContext context) => Container(
    width: 128,
    height: 196,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: const Color(0xFF26231F),
      borderRadius: BorderRadius.circular(22),
      boxShadow: _shade,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: ColoredBox(
        color: _lit(context, const Color(0xFFF7F5EF)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0x33302318),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(width: 54, height: 7, color: const Color(0x55302318)),
              const SizedBox(height: 12),
              Text(
                words,
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 14,
                  height: 1.3,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A paper napkin with a scalloped edge and a scribble.
class _Napkin extends StatelessWidget {
  const _Napkin(this.words);

  final String words;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(boxShadow: _shade),
    child: ClipPath(
      clipper: const _Scallops(),
      child: Container(
        width: 150,
        height: 140,
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        color: _lit(context, const Color(0xFFFFFDF8)),
        child: CustomPaint(
          painter: const _Emboss(),
          child: Center(
            child: Text(
              words,
              textAlign: TextAlign.center,
              style: _scribble(context, color: const Color(0xFF7A1414)),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Scallops extends CustomClipper<Path> {
  const _Scallops();

  @override
  Path getClip(Size size) {
    const r = 6.0;
    final p = Path()..addRect((Offset.zero & size).deflate(r));
    for (var x = r; x < size.width; x += r * 2) {
      p
        ..addOval(Rect.fromCircle(center: Offset(x, r), radius: r))
        ..addOval(
          Rect.fromCircle(center: Offset(x, size.height - r), radius: r),
        );
    }
    for (var y = r; y < size.height; y += r * 2) {
      p
        ..addOval(Rect.fromCircle(center: Offset(r, y), radius: r))
        ..addOval(
          Rect.fromCircle(center: Offset(size.width - r, y), radius: r),
        );
    }
    return p;
  }

  @override
  bool shouldReclip(_Scallops old) => false;
}

/// The napkin's pressed pattern: a faint diamond grid.
class _Emboss extends CustomPainter {
  const _Emboss();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14302318)
      ..strokeWidth = 1;
    for (var d = -size.height; d < size.width; d += 16) {
      canvas
        ..drawLine(Offset(d, 0), Offset(d + size.height, size.height), paint)
        ..drawLine(Offset(d + size.height, 0), Offset(d, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_Emboss old) => false;
}
