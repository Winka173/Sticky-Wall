import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../services/theme_packs.dart';
import '../theme.dart';
import 'note_views.dart';
import 'photo_frames.dart';
import 'settings_sheet.dart' show pinStyleLabel, wallLabel;
import 'stickers.dart';
import 'thread_style.dart';

/// The parts of Sticky Wall Pro, each with its own little film on the Pro
/// sheet. A Pro thing tapped without Pro opens the sheet on its part.
enum ProPerk {
  walls,
  themePacks,
  seasons,
  fonts,
  papers,
  paperStyles,
  pins,
  stickers,
  frames,
  threads,
  markers,
  privateBoards,
}

/// [perk] acted out on a little wall made of the app's own pieces (its real
/// walls, papers, pins, stickers, frames and threads), drawn on a fixed
/// 320 × 180 stage and scaled to fit. `t` runs 0 to 1; t = 1 is the still
/// that explains the part on its own (reduced motion and the list's
/// thumbnails show only that frame). The drawing ignores the system text
/// size; the sheet reads a label aloud instead.
Widget proDemo(BuildContext context, ProPerk perk, double t) =>
    MediaQuery.withNoTextScaling(
      child: FittedBox(
        child: SizedBox(
          width: 320,
          height: 180,
          child: switch (perk) {
            ProPerk.walls => _Walls(t),
            ProPerk.themePacks => _Packs(t),
            ProPerk.seasons => _Seasons(t),
            ProPerk.fonts => _Fonts(t),
            ProPerk.papers => _Papers(t),
            ProPerk.paperStyles => _PaperStyles(t),
            ProPerk.pins => _Pins(t),
            ProPerk.stickers => _Stickers(t),
            ProPerk.frames => _Frames(t),
            ProPerk.threads => _Threads(t),
            ProPerk.markers => _Markers(t),
            ProPerk.privateBoards => _Private(t),
          },
        ),
      ),
    );

// --- Timing ---------------------------------------------------------------

/// 0 before [a], 1 after [b], eased in between.
double _seg(double t, double a, double b) =>
    Curves.easeInOutCubic.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// A pop from nothing that overshoots a little, for scales.
double _pop(double t, double a, double b) =>
    Curves.easeOutBack.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// Which of [n] equal phases t is in (the last one at t = 1).
int _phase(double t, int n) => (t * n).floor().clamp(0, n - 1);

/// [n] items spread evenly over [all], first and last included.
List<T> _spread<T>(List<T> all, int n) {
  if (all.length <= n) return all;
  return [
    for (var i = 0; i < n; i++) all[(i * (all.length - 1) / (n - 1)).round()],
  ];
}

final _cork = walls.first;

// --- Pieces ---------------------------------------------------------------

/// A wall texture filling the stage, with [child] on it.
class _Wall extends StatelessWidget {
  const _Wall(this.wall, {this.child});

  final WallStyle wall;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(wall.asset, fit: BoxFit.cover),
      ColoredBox(color: wall.overlay),
      ?child,
    ],
  );
}

/// [child] placed with its top-left corner at ([x], [y]) on the stage.
Widget _at(double x, double y, Widget child) =>
    Positioned(left: x, top: y, child: child);

/// The app's own pin in [style], whatever the board uses.
class _Pin extends StatelessWidget {
  const _Pin(this.style, {this.seed = ''});

  final PinStyle style;
  final String seed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        extensions: [
          for (final e in theme.extensions.values)
            if (e is! PinLook) e,
          PinLook(style),
        ],
      ),
      child: NotePin(pinned: false, seed: seed),
    );
  }
}

/// A small sticky note: paper, its ruling, a few lines of handwriting (or
/// [text] in [font]) and a pin.
class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.color,
    this.size = const Size(62, 58),
    this.style = PaperStyle.plain,
    this.pin = PinStyle.classic,
    this.showPin = true,
    this.text,
    this.font,
    this.fontSize = 12,
    this.seed = 'a',
    this.angle = 0,
    this.textOpacity = 1,
  });

  /// How much of [text] shows, for writing that changes on the same paper.
  final double textOpacity;

  final Color color;
  final Size size;
  final PaperStyle style;
  final PinStyle pin;
  final bool showPin;
  final String? text;
  final FontChoice? font;
  final double fontSize;
  final String seed;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final f = font ?? fontChoices.first;
    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: size.width,
        height: size.height + 7,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadii.paper),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (style != PaperStyle.plain)
                      CustomPaint(
                        painter: PaperPatternPainter(style, line: 9, top: 6),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(7, 11, 6, 5),
                      child: text == null
                          ? CustomPaint(painter: _Scribble(seed))
                          : Opacity(
                              opacity: textOpacity,
                              child: Text(
                                text!,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                  fontFamily: f.family,
                                  fontSize: fontSize * f.scale,
                                  height: 1.15,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (showPin)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(child: _Pin(pin, seed: seed)),
              ),
          ],
        ),
      ),
    );
  }
}

/// A few lines of handwriting, wavy ink of different lengths.
class _Scribble extends CustomPainter {
  const _Scribble(this.seed);

  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink.withValues(alpha: .7)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final h = stableHash(seed);
    const gap = 9.0;
    for (var row = 0; row * gap + 4 < size.height - 2; row++) {
      final end = size.width * (0.55 + ((h >> (row * 3)) % 40) / 100);
      final y = 4 + row * gap;
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x < end; x += 3) {
        path.lineTo(x, y + math.sin(x * 0.9 + row + h % 7) * 1.4);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_Scribble old) => old.seed != seed;
}

/// A small paper label naming what is shown.
class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.paper.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(AppRadii.control),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
      ],
    ),
    child: Text(
      text,
      maxLines: 1,
      style: const TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    ),
  );
}

/// The tag in the bottom-left corner of the stage.
Widget _corner(String text) =>
    Positioned(left: 8, bottom: 8, child: _Tag(text));

/// One stage fading in over the one below it.
Widget _fadeIn(double v, Widget child) => Positioned.fill(
  child: Opacity(opacity: v, child: child),
);

/// [child] growing out of nothing with a little overshoot.
Widget _popIn(double v, Widget child, {double turn = 0}) => Opacity(
  opacity: v.clamp(0.0, 1.0),
  child: Transform.rotate(
    angle: turn * (1 - v),
    child: Transform.scale(scale: 0.4 + 0.6 * v, child: child),
  ),
);

/// Three free notes, the same on every wall the demos change.
List<Widget> _threeNotes() => [
  _at(46, 40, _Sheet(color: AppColors.notePapers[0], seed: 'w1', angle: -.06)),
  _at(132, 62, _Sheet(color: AppColors.notePapers[1], seed: 'w2', angle: .04)),
  _at(214, 36, _Sheet(color: AppColors.notePapers[2], seed: 'w3', angle: -.03)),
];

// --- The demos ------------------------------------------------------------

/// The wall changes from one Pro texture to the next under the notes.
class _Walls extends StatelessWidget {
  const _Walls(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ws = _spread(
      walls.where((w) => w.pro && w.season == null).toList(),
      4,
    );
    final fades = [
      for (var k = 1; k < ws.length; k++) _seg(t, k * .27 - .1, k * .27 + .04),
    ];
    final shown = fades.where((v) => v > .5).length;
    return Stack(
      children: [
        Positioned.fill(child: _Wall(ws.first)),
        for (var k = 1; k < ws.length; k++) _fadeIn(fades[k - 1], _Wall(ws[k])),
        ..._threeNotes(),
        _corner(wallLabel(l10n, ws[shown].id)),
      ],
    );
  }
}

/// A little board: its wall, three notes in the pack's papers, font and
/// pins, and a thread between two of them.
class _PackBoard extends StatelessWidget {
  const _PackBoard(this.pack);

  final ThemePack pack;

  @override
  Widget build(BuildContext context) {
    final font = fontChoiceById(pack.font);
    final preview = AppLocalizations.of(context)!.fontPreview;
    Widget note(int i, double x, double y, double angle) => _at(
      x,
      y,
      _Sheet(
        color: paperColorOf(context, pack.paperAt(i), ''),
        style: pack.paper.suits(NoteType.normal)
            ? pack.paper
            : PaperStyle.plain,
        pin: pack.pin,
        font: font,
        text: i == 0 ? preview : null,
        fontSize: 11,
        seed: '${pack.id}$i',
        angle: angle,
        size: const Size(70, 62),
      ),
    );
    return _Wall(
      pack.wallStyle,
      child: Stack(
        children: [
          note(0, 40, 34, -.05),
          note(1, 134, 70, .04),
          note(2, 222, 30, -.02),
          Positioned.fill(
            child: CustomPaint(
              painter: _ThreadsPainter([
                _Tie(
                  const Offset(75, 41),
                  const Offset(169, 77),
                  Color(pack.yarn),
                  pack.thread,
                  1,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// One board takes on three Pro theme packs in turn.
class _Packs extends StatelessWidget {
  const _Packs(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final ps = _spread(
      themePacks.where((p) => p.pro && p.wallStyle.season == null).toList(),
      3,
    );
    final fades = [_seg(t, .28, .42), _seg(t, .62, .76)];
    final shown = fades.where((v) => v > .5).length;
    return Stack(
      children: [
        Positioned.fill(child: _PackBoard(ps[0])),
        for (var k = 1; k < ps.length; k++)
          _fadeIn(fades[k - 1], _PackBoard(ps[k])),
        _corner(ps[shown].name(lang)),
      ],
    );
  }
}

/// Christmas, Valentine's, Mid-Autumn and Tết: each wall with a sticker of
/// its pack.
class _Seasons extends StatelessWidget {
  const _Seasons(this.t);

  final double t;

  static const _order = [
    Season.christmas,
    Season.valentine,
    Season.midAutumn,
    Season.tet,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String name(Season s) => switch (s) {
      Season.tet => l10n.packTet,
      Season.christmas => l10n.packChristmas,
      Season.midAutumn => l10n.packMidAutumn,
      Season.valentine => l10n.packValentine,
    };
    final n = _order.length;
    final now = _phase(t, n);
    return Stack(
      children: [
        for (var k = 0; k < n; k++)
          _fadeIn(
            k == 0 ? 1 : _seg(t, k / n - .05, k / n + .05),
            _Wall(walls.firstWhere((w) => w.season == _order[k])),
          ),
        _at(
          52,
          46,
          _Sheet(color: AppColors.notePapers[0], seed: 's1', angle: -.05),
        ),
        _at(
          128,
          70,
          _Sheet(color: AppColors.notePapers[3], seed: 's2', angle: .05),
        ),
        for (var k = 0; k < n; k++)
          if (k == now)
            _at(
              214,
              36,
              _popIn(
                _pop(t, k / n + .03, k / n + .14),
                StickerArt(
                  sticker: stickers.firstWhere(
                    (s) => s.pack.season == _order[k],
                  ),
                  width: 74,
                ),
                turn: .3,
              ),
            ),
        _corner(name(_order[now])),
      ],
    );
  }
}

/// One note written out in each Pro handwriting.
class _Fonts extends StatelessWidget {
  const _Fonts(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final fonts = fontChoices.where((f) => f.pro).toList();
    final n = fonts.length;
    final now = _phase(t, n);
    final local = t * n - now;
    final font = fonts[now];
    return _Wall(
      _cork,
      child: Stack(
        children: [
          _at(
            70,
            22,
            _Sheet(
              color: AppColors.notePapers[0],
              size: const Size(180, 120),
              font: font,
              fontSize: 20,
              seed: 'f',
              angle: -.025,
              text: AppLocalizations.of(context)!.fontPreview,
              textOpacity: now == 0 ? 1 : _seg(local, 0, .25),
            ),
          ),
          _corner(font.label),
        ],
      ),
    );
  }
}

/// The Pro papers come out one by one, then one of your own mix.
class _Papers extends StatelessWidget {
  const _Papers(this.t);

  final double t;

  static const _mixed = Color(0xFFFFD6A5);

  @override
  Widget build(BuildContext context) {
    final colors = [
      for (var i = AppColors.freePapers; i < AppColors.notePapers.length; i++)
        paperColorOf(context, i, ''),
      paperColorOf(context, customPaper(_mixed), ''),
    ];
    const per = 4;
    return _Wall(
      _cork,
      child: Stack(
        children: [
          for (var i = 0; i < colors.length; i++)
            _at(
              24.0 + (i % per) * 72 + (i >= per ? 36 : 0),
              i < per ? 14 : 92,
              _popIn(
                _pop(t, .05 + i * .1, .17 + i * .1),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _Sheet(
                      color: colors[i],
                      seed: 'p$i',
                      angle: (i.isEven ? -1 : 1) * .05,
                      size: const Size(58, 54),
                    ),
                    if (i == colors.length - 1)
                      const Positioned(
                        right: -4,
                        bottom: -4,
                        child: _Rainbow(),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The colour wheel that marks a mixed paper.
class _Rainbow extends StatelessWidget {
  const _Rainbow();

  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 18,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      gradient: const SweepGradient(
        colors: [
          Color(0xFFF8BBD0),
          Color(0xFFFFF59D),
          Color(0xFFB2DFDB),
          Color(0xFFB3E5FC),
          Color(0xFFE1BEE7),
          Color(0xFFF8BBD0),
        ],
      ),
    ),
  );
}

/// One sheet ruled in each Pro paper style.
class _PaperStyles extends StatelessWidget {
  const _PaperStyles(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final styles = PaperStyle.values.where((s) => s.pro).toList();
    final n = styles.length;
    final now = _phase(t, n);
    final local = t * n - now;
    Widget sheet(PaperStyle s) => _Sheet(
      color: AppColors.notePapers[now.isEven ? 0 : 3],
      size: const Size(170, 118),
      style: s,
      seed: 'ps',
      angle: .02,
    );
    return _Wall(
      _cork,
      child: Stack(
        children: [
          _at(
            74,
            20,
            Stack(
              children: [
                if (now > 0) sheet(styles[now - 1]),
                Opacity(
                  opacity: now == 0 ? 1 : _seg(local, 0, .3),
                  child: sheet(styles[now]),
                ),
              ],
            ),
          ),
          _corner(paperStyleLabel(l10n, styles[now])),
        ],
      ),
    );
  }
}

/// Five notes, each held up by a different Pro pin as it lands.
class _Pins extends StatelessWidget {
  const _Pins(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pins = PinStyle.values.where((p) => p.pro).toList();
    final drops = [
      for (var i = 0; i < pins.length; i++)
        _seg(t, .06 + i * .17, .2 + i * .17),
    ];
    final last = drops.lastIndexWhere((v) => v > .5);
    return _Wall(
      _cork,
      child: Stack(
        children: [
          for (var i = 0; i < pins.length; i++) ...[
            _at(
              14.0 + i * 60,
              i.isEven ? 52 : 70,
              _Sheet(
                color: AppColors.notePapers[i % AppColors.freePapers],
                seed: 'pin$i',
                showPin: false,
                angle: (i.isEven ? -1 : 1) * .04,
                size: const Size(54, 56),
              ),
            ),
            _at(
              14.0 + i * 60,
              (i.isEven ? 52 : 70) - 30 * (1 - drops[i]),
              Opacity(
                opacity: drops[i],
                child: SizedBox(
                  width: 54,
                  child: Center(child: _Pin(pins[i], seed: 'pin$i')),
                ),
              ),
            ),
          ],
          if (last >= 0) _corner(pinStyleLabel(l10n, pins[last])),
        ],
      ),
    );
  }
}

/// Pro stickers land one after another around a note.
class _Stickers extends StatelessWidget {
  const _Stickers(this.t);

  final double t;

  static const _spots = [
    (176.0, 14.0, 58.0),
    (238.0, 64.0, 62.0),
    (168.0, 100.0, 54.0),
    (24.0, 104.0, 52.0),
    (252.0, 4.0, 46.0),
  ];

  @override
  Widget build(BuildContext context) {
    bool art(Sticker s) =>
        s.pro && s.pack.season == null && s.kind == StickerKind.image;
    // Illustrations, then one washi tape across the corner.
    final picks = [
      ..._spread(
        stickers.where((s) => art(s) && s.pack != StickerPack.tapes).toList(),
        _spots.length - 1,
      ),
      stickers.firstWhere((s) => art(s) && s.pack == StickerPack.tapes),
    ];
    return _Wall(
      walls.firstWhere((w) => w.id == 'kraft', orElse: () => _cork),
      child: Stack(
        children: [
          _at(
            56,
            26,
            _Sheet(
              color: AppColors.notePapers[1],
              size: const Size(104, 96),
              seed: 'st',
              angle: -.04,
            ),
          ),
          for (var i = 0; i < picks.length; i++)
            _at(
              _spots[i].$1,
              _spots[i].$2,
              _popIn(
                _pop(t, .06 + i * .16, .2 + i * .16),
                StickerArt(sticker: picks[i], width: _spots[i].$3),
                turn: (i.isEven ? 1 : -1) * .5,
              ),
            ),
        ],
      ),
    );
  }
}

/// Four photo prints, each in a Pro frame.
class _Frames extends StatelessWidget {
  const _Frames(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final frames = PhotoFrame.values.where((f) => f.pro).toList();
    final pops = [
      for (var i = 0; i < frames.length; i++)
        _pop(t, .06 + i * .2, .22 + i * .2),
    ];
    final last = pops.lastIndexWhere((v) => v > .5);
    return _Wall(
      _cork,
      child: Stack(
        children: [
          for (var i = 0; i < frames.length; i++)
            _at(
              12.0 + i * 76,
              i.isEven ? 22 : 40,
              _popIn(
                pops[i],
                Transform.rotate(
                  angle: (i.isEven ? -1 : 1) * .06,
                  child: SizedBox(
                    width: 70,
                    child: FittedBox(
                      child: SizedBox(
                        width: 130,
                        child: FramedPrint(
                          frame: frames[i],
                          seed: 'fr$i',
                          paper: AppColors.notePapers[i],
                          photo: SizedBox(
                            height: 110,
                            width: double.infinity,
                            child: CustomPaint(painter: _Snapshot(i)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (last >= 0) _corner(photoFrameName(l10n, frames[last])),
        ],
      ),
    );
  }
}

/// A painted holiday snap: sky, sun, hills and water, in a few moods.
class _Snapshot extends CustomPainter {
  const _Snapshot(this.mood);

  final int mood;

  static const _skies = [
    [Color(0xFF8EC5FC), Color(0xFFE0F2FF)],
    [Color(0xFFFFB88C), Color(0xFFFFE6C7)],
    [Color(0xFF6A85B6), Color(0xFFBAC8E0)],
    [Color(0xFFA1E3D8), Color(0xFFF1FAEE)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sky = _skies[mood % _skies.length];
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * (.25 + .15 * mood), size.height * .32),
      size.height * .12,
      Paint()..color = const Color(0xFFFFF3B0),
    );
    final far = Path()
      ..moveTo(0, size.height * .62)
      ..quadraticBezierTo(
        size.width * .3,
        size.height * .38,
        size.width * .6,
        size.height * .6,
      )
      ..quadraticBezierTo(
        size.width * .8,
        size.height * .48,
        size.width,
        size.height * .58,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFF7FA67A));
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * .76, size.width, size.height),
      Paint()..color = const Color(0xFF5E9BB5),
    );
  }

  @override
  bool shouldRepaint(_Snapshot old) => old.mood != mood;
}

/// One thread between two pins, drawn up to [progress].
class _Tie {
  const _Tie(this.from, this.to, this.color, this.style, this.progress);

  final Offset from, to;
  final Color color;
  final ThreadStyle style;
  final double progress;
}

class _ThreadsPainter extends CustomPainter {
  const _ThreadsPainter(this.ties);

  final List<_Tie> ties;

  @override
  void paint(Canvas canvas, Size size) {
    for (final tie in ties) {
      if (tie.progress <= 0) continue;
      // A thread sags a little between its pins, as on the wall.
      final mid = Offset.lerp(tie.from, tie.to, .5)! + const Offset(0, 16);
      final full = Path()
        ..moveTo(tie.from.dx, tie.from.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, tie.to.dx, tie.to.dy);
      final path = Path();
      for (final m in full.computeMetrics()) {
        path.addPath(m.extractPath(0, m.length * tie.progress), Offset.zero);
      }
      canvas.drawPath(
        path.shift(const Offset(1, 2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.black.withValues(alpha: .18),
      );
      paintThreadLine(canvas, path, tie.color, tie.style);
    }
  }

  @override
  bool shouldRepaint(_ThreadsPainter old) => true;
}

/// Four notes tied together with the four Pro threads, one after another.
class _Threads extends StatelessWidget {
  const _Threads(this.t);

  final double t;

  static const _notes = [
    Offset(18, 30),
    Offset(96, 92),
    Offset(176, 24),
    Offset(250, 88),
  ];

  @override
  Widget build(BuildContext context) {
    final styles = ThreadStyle.values.where((s) => s.pro).toList();
    final colors = [
      for (var i = AppColors.freeYarns; i < AppColors.yarns.length; i++)
        Color(AppColors.yarns[i]),
    ];
    // The pin sits at the top middle of each note.
    Offset pin(int i) => _notes[i] + const Offset(28, 4);
    return _Wall(
      _cork,
      child: Stack(
        children: [
          for (var i = 0; i < _notes.length; i++)
            _at(
              _notes[i].dx,
              _notes[i].dy,
              _Sheet(
                color: AppColors.notePapers[(i + 2) % AppColors.freePapers],
                seed: 'th$i',
                size: const Size(56, 52),
              ),
            ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ThreadsPainter([
                for (var i = 0; i < styles.length; i++)
                  _Tie(
                    pin(i % _notes.length),
                    pin((i + 1) % _notes.length),
                    colors[i % colors.length],
                    styles[i],
                    _seg(t, .05 + i * .22, .25 + i * .22),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circles, ticks and arrows in the Pro marker colours on a chalkboard.
class _Markers extends StatelessWidget {
  const _Markers(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final colors = [
      for (var i = AppColors.freeMarkers; i < AppColors.markers.length; i++)
        Color(AppColors.markers[i]),
    ];
    return _Wall(
      walls.firstWhere((w) => w.id == 'chalk_black', orElse: () => _cork),
      child: Stack(
        children: [
          _at(
            40,
            40,
            _Sheet(color: AppColors.notePapers[0], seed: 'm1', angle: -.05),
          ),
          _at(
            200,
            54,
            _Sheet(color: AppColors.notePapers[2], seed: 'm2', angle: .04),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _StrokesPainter(colors, t)),
          ),
        ],
      ),
    );
  }
}

class _StrokesPainter extends CustomPainter {
  const _StrokesPainter(this.colors, this.t);

  final List<Color> colors;
  final double t;

  static List<Path> _strokes() => [
    // A ring round the first note.
    Path()..addOval(const Rect.fromLTWH(26, 34, 92, 86)),
    // An arrow from it to the second.
    Path()
      ..moveTo(122, 92)
      ..quadraticBezierTo(158, 118, 192, 92)
      ..moveTo(180, 86)
      ..lineTo(193, 92)
      ..lineTo(183, 103),
    // A tick beside the second note.
    Path()
      ..moveTo(270, 64)
      ..lineTo(280, 76)
      ..lineTo(300, 46),
    // A wavy underline.
    Path()..addPolygon([
      for (var x = 40.0; x <= 290; x += 10)
        Offset(x, 150 + math.sin(x / 9) * 4),
    ], false),
    // A star in the corner.
    Path()..addPolygon([
      for (var i = 0; i <= 10; i++)
        Offset(150, 30) +
            Offset.fromDirection(
              -math.pi / 2 + i * math.pi / 5,
              i.isEven ? 16 : 7,
            ),
    ], false),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final strokes = _strokes();
    for (var i = 0; i < strokes.length; i++) {
      final v = _seg(t, .04 + i * .18, .2 + i * .18);
      if (v <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = colors[i % colors.length];
      for (final m in strokes[i].computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * v), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_StrokesPainter old) => old.t != t;
}

/// A board's notes blur away behind a lock that only your fingerprint or
/// screen lock opens.
class _Private extends StatelessWidget {
  const _Private(this.t);

  final double t;

  @override
  Widget build(BuildContext context) {
    final shut = _seg(t, .22, .5);
    final lock = _pop(t, .45, .62);
    final finger = _seg(t, .62, .8);
    // The fingerprint glows twice once it is shown.
    final pulse = finger * (.65 + .35 * math.sin(t * math.pi * 6).abs());
    return _Wall(
      walls.firstWhere((w) => w.id == 'wood', orElse: () => _cork),
      child: Stack(
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: 7 * shut,
                sigmaY: 7 * shut,
              ),
              child: Stack(children: _threeNotes()),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.ink.withValues(alpha: .28 * shut),
            ),
          ),
          Center(
            child: _popIn(
              lock,
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(AppRadii.control * 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 30, color: AppColors.ink),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: pulse,
                      child: const Icon(
                        Icons.fingerprint,
                        size: 34,
                        color: AppColors.proInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
