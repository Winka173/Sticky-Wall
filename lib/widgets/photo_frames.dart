import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../theme.dart';

/// The print white for a frame, dimmed with the lights off like the rest.
Color frameWhite(BuildContext context) => printColorOf(context);

/// A photo print in [frame]: [photo] is the picture, [caption] what is
/// written under it (null for none), [paper] the note's own colour (used by
/// the scrapbook layer), [seed] keeps a torn edge or a tilt the same on
/// every frame. [selected] and [raised] as for any card.
class FramedPrint extends StatelessWidget {
  const FramedPrint({
    super.key,
    required this.frame,
    required this.photo,
    required this.seed,
    required this.paper,
    this.caption,
    this.selected = false,
    this.raised = false,
  });

  final PhotoFrame frame;
  final Widget photo;
  final Widget? caption;
  final String seed;
  final Color paper;
  final bool selected;
  final bool raised;

  List<BoxShadow> get _shadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: raised ? 0.38 : 0.28),
      blurRadius: raised ? 16 : 7,
      offset: Offset(raised ? 4 : 2, raised ? 10 : 4),
    ),
  ];

  Border? get _outline =>
      selected ? Border.all(color: AppColors.ink, width: 2.5) : null;

  @override
  Widget build(BuildContext context) {
    final white = frameWhite(context);
    switch (frame) {
      case PhotoFrame.print:
        return _plain(white, const EdgeInsets.fromLTRB(6, 10, 6, 6), 2);
      case PhotoFrame.polaroid:
        // The wide bottom margin is where a polaroid gets written on.
        return Container(
          decoration: BoxDecoration(
            color: Color.lerp(white, const Color(0xFFF3ECDC), 0.5),
            borderRadius: BorderRadius.circular(2),
            border: _outline,
            boxShadow: _shadow,
          ),
          padding: const EdgeInsets.fromLTRB(9, 12, 9, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              photo,
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                child: caption ?? const SizedBox(height: 22),
              ),
            ],
          ),
        );
      case PhotoFrame.film:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: _outline,
            boxShadow: _shadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomPaint(
                painter: _FilmPainter(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                  child: photo,
                ),
              ),
              if (caption case final c?)
                ColoredBox(
                  color: white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                    child: c,
                  ),
                ),
            ],
          ),
        );
      case PhotoFrame.vintage:
        // A cream card with a deckled edge, the picture warmed like an old
        // print.
        return DecoratedBox(
          decoration: BoxDecoration(boxShadow: _shadow),
          child: ClipPath(
            clipper: _DeckleClipper(),
            child: Container(
              color: Color.lerp(white, const Color(0xFFE9DCC0), 0.75),
              foregroundDecoration: BoxDecoration(border: _outline),
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ColorFiltered(colorFilter: _sepia, child: photo),
                  if (caption case final c?)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 7, 2, 0),
                      child: c,
                    ),
                ],
              ),
            ),
          ),
        );
      case PhotoFrame.torn:
        return CustomPaint(
          painter: _TornShadowPainter(seed, raised: raised),
          child: ClipPath(
            clipper: _TornClipper(seed),
            child: Container(
              color: white,
              foregroundDecoration: BoxDecoration(border: _outline),
              padding: const EdgeInsets.fromLTRB(11, 13, 11, 11),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  photo,
                  if (caption case final c?)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
                      child: c,
                    ),
                ],
              ),
            ),
          ),
        );
      case PhotoFrame.rounded:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: _outline,
                boxShadow: _shadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: photo,
              ),
            ),
            if (caption case final c?)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 4),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: c,
                  ),
                ),
              ),
          ],
        );
      case PhotoFrame.scrapbook:
        // A sheet of the note's paper behind, a little askew, the print on
        // top held by four photo corners.
        final tilt = ((stableHash(seed) % 7) - 3) / 100;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Transform.rotate(
                angle: tilt - 0.05,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: paper,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: _shadow,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: white,
                border: _outline,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 3,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomPaint(
                    foregroundPainter: _CornersPainter(),
                    child: photo,
                  ),
                  if (caption case final c?)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
                      child: c,
                    ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _plain(Color white, EdgeInsets padding, double radius) => Container(
    decoration: BoxDecoration(
      color: white,
      borderRadius: BorderRadius.circular(AppRadii.paper),
      border: _outline,
      boxShadow: _shadow,
    ),
    padding: padding,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        photo,
        if (caption case final c?)
          Padding(padding: const EdgeInsets.fromLTRB(4, 6, 4, 2), child: c),
      ],
    ),
  );

  static const _sepia = ColorFilter.matrix([
    0.85, 0.18, 0.05, 0, 8, //
    0.10, 0.80, 0.08, 0, 6, //
    0.08, 0.14, 0.62, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);
}

/// A strip of dark film with sprocket holes along both edges.
class _FilmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(2)),
      Paint()..color = const Color(0xFF1F1B18),
    );
    final hole = Paint()..color = const Color(0xFFEDE6D6);
    const w = 7.0, h = 5.0, gap = 7.0;
    final count = ((size.width - gap) / (w + gap)).floor();
    final start = (size.width - count * (w + gap) + gap) / 2;
    for (var i = 0; i < count; i++) {
      final x = start + i * (w + gap);
      for (final y in [5.5, size.height - 5.5 - h]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h),
            const Radius.circular(1.2),
          ),
          hole,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FilmPainter oldDelegate) => false;
}

/// A deckled (scalloped) edge all round, like an old photo.
class _DeckleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const bump = 3.0;
    const step = 7.0;
    final path = Path()..moveTo(0, bump);
    void edge(Offset from, Offset to, Offset out) {
      final length = (to - from).distance;
      final n = math.max(1, (length / step).round());
      for (var i = 0; i < n; i++) {
        final a = Offset.lerp(from, to, i / n)!;
        final b = Offset.lerp(from, to, (i + 1) / n)!;
        final mid = Offset.lerp(a, b, 0.5)! + out;
        path.quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      }
    }

    final tl = const Offset(bump, bump);
    final tr = Offset(size.width - bump, bump);
    final br = Offset(size.width - bump, size.height - bump);
    final bl = Offset(bump, size.height - bump);
    path.moveTo(tl.dx, tl.dy);
    edge(tl, tr, const Offset(0, -bump));
    edge(tr, br, const Offset(bump, 0));
    edge(br, bl, const Offset(0, bump));
    edge(bl, tl, const Offset(-bump, 0));
    return path..close();
  }

  @override
  bool shouldReclip(_DeckleClipper oldClipper) => false;
}

/// The outline of a sheet torn by hand: small irregular teeth, the same for
/// the same [seed].
Path tornPath(Size size, String seed) {
  final rng = math.Random(stableHash(seed));
  const depth = 3.5;
  final path = Path();
  final points = <Offset>[];
  void edge(Offset from, Offset to, Offset inward) {
    final length = (to - from).distance;
    final n = math.max(2, (length / 6).round());
    for (var i = 0; i < n; i++) {
      final p = Offset.lerp(from, to, i / n)!;
      points.add(p + inward * (rng.nextDouble() * depth));
    }
  }

  edge(Offset.zero, Offset(size.width, 0), const Offset(0, 1));
  edge(
    Offset(size.width, 0),
    Offset(size.width, size.height),
    const Offset(-1, 0),
  );
  edge(
    Offset(size.width, size.height),
    Offset(0, size.height),
    const Offset(0, -1),
  );
  edge(Offset(0, size.height), Offset.zero, const Offset(1, 0));
  path.addPolygon(points, true);
  return path;
}

class _TornClipper extends CustomClipper<Path> {
  _TornClipper(this.seed);
  final String seed;

  @override
  Path getClip(Size size) => tornPath(size, seed);

  @override
  bool shouldReclip(_TornClipper oldClipper) => oldClipper.seed != seed;
}

/// The torn sheet's shadow, following its ragged outline.
class _TornShadowPainter extends CustomPainter {
  _TornShadowPainter(this.seed, {required this.raised});
  final String seed;
  final bool raised;

  @override
  void paint(Canvas canvas, Size size) {
    final path = tornPath(
      size,
      seed,
    ).shift(raised ? const Offset(4, 10) : const Offset(2, 4));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: raised ? 0.34 : 0.26)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, raised ? 8 : 4),
    );
  }

  @override
  bool shouldRepaint(_TornShadowPainter old) =>
      old.seed != seed || old.raised != raised;
}

/// Four dark paper photo corners holding the picture.
class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xE62E2A25);
    const s = 16.0;
    final w = size.width, h = size.height;
    for (final corner in [
      [Offset.zero, const Offset(s, 0), const Offset(0, s)],
      [Offset(w, 0), Offset(w - s, 0), Offset(w, s)],
      [Offset(0, h), Offset(s, h), Offset(0, h - s)],
      [Offset(w, h), Offset(w - s, h), Offset(w, h - s)],
    ]) {
      canvas.drawPath(Path()..addPolygon(corner, true), paint);
    }
  }

  @override
  bool shouldRepaint(_CornersPainter oldDelegate) => false;
}

/// The frame's name, as the picker and the screen reader say it.
String photoFrameName(AppLocalizations l10n, PhotoFrame frame) =>
    switch (frame) {
      PhotoFrame.print => l10n.framePrint,
      PhotoFrame.polaroid => l10n.framePolaroid,
      PhotoFrame.film => l10n.frameFilm,
      PhotoFrame.vintage => l10n.frameVintage,
      PhotoFrame.torn => l10n.frameTorn,
      PhotoFrame.rounded => l10n.frameRounded,
      PhotoFrame.scrapbook => l10n.frameScrapbook,
    };

/// A row of every frame around a small sample picture; returns the one
/// tapped, or null.
Future<PhotoFrame?> showFramePicker(
  BuildContext context, {
  PhotoFrame? current,
  String? title,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<PhotoFrame>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title ?? l10n.photoFrame,
            style: const TextStyle(fontSize: 20, color: AppColors.ink),
          ),
          SizedBox(
            height: 210,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                for (final f in PhotoFrame.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: Semantics(
                      button: true,
                      selected: f == current,
                      label: photoFrameName(l10n, f),
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, f),
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 104,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 140,
                                child: Center(
                                  child: FramedPrint(
                                    frame: f,
                                    seed: 'sample${f.name}',
                                    paper: AppColors.notePapers[1],
                                    selected: f == current,
                                    photo: const _SamplePhoto(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                photoFrameName(l10n, f),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// A stand-in picture for the frame samples: sky, sun and a hill.
class _SamplePhoto extends StatelessWidget {
  const _SamplePhoto();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 62, child: CustomPaint(painter: _SamplePainter()));
  }
}

class _SamplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8EC5E8), Color(0xFFF6D7A7)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.32),
      size.height * 0.14,
      Paint()..color = const Color(0xFFFFF3C4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..quadraticBezierTo(
          size.width * 0.4,
          size.height * 0.45,
          size.width,
          size.height * 0.8,
        )
        ..lineTo(size.width, size.height)
        ..close(),
      Paint()..color = const Color(0xFF7FA66A),
    );
  }

  @override
  bool shouldRepaint(_SamplePainter oldDelegate) => false;
}
