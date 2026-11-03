import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/pro_controller.dart';
import '../theme.dart';
import 'keyboard_tappable.dart';
import 'pro_sheet.dart';

/// How a sticker is drawn: a big emoji, a rubber stamp with a word on it, or
/// a marker doodle painted in code (so the set costs no download size).
enum StickerKind { emoji, stamp, doodle }

/// Which shelf of the picker a sticker sits on: everyday ones, or a
/// season's pack (Sticky Wall Pro), offered only around its occasion.
enum StickerPack {
  everyday(null),
  tet(Season.tet),
  christmas(Season.christmas),
  midAutumn(Season.midAutumn),
  valentine(Season.valentine);

  const StickerPack(this.season);

  final Season? season;

  bool get inSeason => season == null || seasonOpen(season!);
}

/// One sticker in the set. [id] is what a sticker note stores, so ids are
/// never renamed or reused.
class Sticker {
  const Sticker(
    this.id,
    this.kind, {
    this.emoji = '',
    this.ink = 0,
    this.pack = StickerPack.everyday,
  });

  final String id;
  final StickerKind kind;

  /// The character an [StickerKind.emoji] sticker shows.
  final String emoji;

  /// The ink of a stamp or doodle (ARGB).
  final int ink;

  final StickerPack pack;

  /// The first three emoji come with the app, so stickers can be found and
  /// tried; the rest are Sticky Wall Pro's.
  bool get pro => !_free.contains(id);

  static const _free = {'star', 'heart', 'check'};
}

const stickers = [
  Sticker('star', StickerKind.emoji, emoji: '⭐'),
  Sticker('heart', StickerKind.emoji, emoji: '❤️'),
  Sticker('check', StickerKind.emoji, emoji: '✅'),
  Sticker('fire', StickerKind.emoji, emoji: '🔥'),
  Sticker('idea', StickerKind.emoji, emoji: '💡'),
  Sticker('warning', StickerKind.emoji, emoji: '⚠️'),
  Sticker('party', StickerKind.emoji, emoji: '🎉'),
  Sticker('thumbs', StickerKind.emoji, emoji: '👍'),
  Sticker('question', StickerKind.emoji, emoji: '❓'),
  Sticker('coffee', StickerKind.emoji, emoji: '☕'),
  Sticker('urgent', StickerKind.stamp, ink: 0xFFC62828),
  Sticker('done', StickerKind.stamp, ink: 0xFF2E7D32),
  Sticker('important', StickerKind.stamp, ink: 0xFFAD1457),
  Sticker('later', StickerKind.stamp, ink: 0xFF1565C0),
  Sticker('arrow', StickerKind.doodle, ink: 0xFFD32F2F),
  Sticker('circle', StickerKind.doodle, ink: 0xFFD32F2F),
  Sticker('underline', StickerKind.doodle, ink: 0xFF1E63C6),
  Sticker('ring', StickerKind.doodle, ink: 0x995D3A1A),
  // Tết.
  Sticker('lixi', StickerKind.emoji, emoji: '🧧', pack: StickerPack.tet),
  Sticker('lantern', StickerKind.emoji, emoji: '🏮', pack: StickerPack.tet),
  Sticker('firecracker', StickerKind.emoji, emoji: '🧨', pack: StickerPack.tet),
  Sticker('mai', StickerKind.doodle, ink: 0xFFF9A825, pack: StickerPack.tet),
  Sticker('dao', StickerKind.doodle, ink: 0xFFEC407A, pack: StickerPack.tet),
  Sticker('newyear', StickerKind.stamp, ink: 0xFFC62828, pack: StickerPack.tet),
  // Christmas.
  Sticker('tree', StickerKind.emoji, emoji: '🎄', pack: StickerPack.christmas),
  Sticker('santa', StickerKind.emoji, emoji: '🎅', pack: StickerPack.christmas),
  Sticker('snow', StickerKind.emoji, emoji: '❄️', pack: StickerPack.christmas),
  Sticker('gift', StickerKind.emoji, emoji: '🎁', pack: StickerPack.christmas),
  Sticker(
    'merry',
    StickerKind.stamp,
    ink: 0xFF2E7D32,
    pack: StickerPack.christmas,
  ),
  // Mid-Autumn.
  Sticker('moon', StickerKind.emoji, emoji: '🌕', pack: StickerPack.midAutumn),
  Sticker(
    'rabbit',
    StickerKind.emoji,
    emoji: '🐇',
    pack: StickerPack.midAutumn,
  ),
  Sticker(
    'starlantern',
    StickerKind.doodle,
    ink: 0xFFD32F2F,
    pack: StickerPack.midAutumn,
  ),
  Sticker(
    'midautumn',
    StickerKind.stamp,
    ink: 0xFFE65100,
    pack: StickerPack.midAutumn,
  ),
  // Valentine.
  Sticker(
    'loveletter',
    StickerKind.emoji,
    emoji: '💌',
    pack: StickerPack.valentine,
  ),
  Sticker('rose', StickerKind.emoji, emoji: '🌹', pack: StickerPack.valentine),
  Sticker(
    'hearts',
    StickerKind.emoji,
    emoji: '💕',
    pack: StickerPack.valentine,
  ),
  Sticker(
    'love',
    StickerKind.stamp,
    ink: 0xFFD81B60,
    pack: StickerPack.valentine,
  ),
];

/// The heading of a pack's shelf in the picker.
String stickerPackLabel(AppLocalizations l10n, StickerPack pack) =>
    switch (pack) {
      StickerPack.everyday => l10n.packEveryday,
      StickerPack.tet => l10n.packTet,
      StickerPack.christmas => l10n.packChristmas,
      StickerPack.midAutumn => l10n.packMidAutumn,
      StickerPack.valentine => l10n.packValentine,
    };

/// The sticker with [id]; unknown ids (from a newer version) show a star.
Sticker stickerById(String id) =>
    stickers.firstWhere((s) => s.id == id, orElse: () => stickers.first);

/// The words a stamp carries, or a doodle's spoken name; an emoji sticker
/// is read out by its character.
String stickerLabel(AppLocalizations l10n, Sticker sticker) =>
    switch (sticker.id) {
      'urgent' => l10n.stampUrgent,
      'done' => l10n.stampDone,
      'important' => l10n.stampImportant,
      'later' => l10n.stampLater,
      'newyear' => l10n.stampNewYear,
      'merry' => l10n.stampMerry,
      'midautumn' => l10n.stampMidAutumn,
      'love' => l10n.stampLove,
      'mai' => l10n.stickerMai,
      'dao' => l10n.stickerDao,
      'starlantern' => l10n.stickerStarLantern,
      'arrow' => l10n.stickerArrow,
      'circle' => l10n.stickerCircle,
      'underline' => l10n.stickerUnderline,
      'ring' => l10n.stickerRing,
      _ => sticker.emoji,
    };

/// A sticker drawn [width] wide: square for emoji and doodles, a flat
/// oblong for stamps.
class StickerArt extends StatelessWidget {
  const StickerArt({super.key, required this.sticker, required this.width});

  final Sticker sticker;
  final double width;

  /// Height for [width]: stamps are long and low, the rest square.
  static double heightFor(Sticker sticker, double width) =>
      sticker.kind == StickerKind.stamp ? width * 0.42 : width;

  @override
  Widget build(BuildContext context) {
    final night = isNight(context);
    final height = heightFor(sticker, width);
    final Widget art = switch (sticker.kind) {
      StickerKind.emoji => Center(
        child: Text(
          sticker.emoji,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontSize: width * 0.78,
            height: 1,
            shadows: const [
              Shadow(
                color: Colors.black38,
                blurRadius: 4,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
      StickerKind.stamp => _Stamp(
        text: stickerLabel(AppLocalizations.of(context)!, sticker),
        ink: Color(sticker.ink),
        height: height,
      ),
      StickerKind.doodle => CustomPaint(
        painter: _DoodlePainter(sticker.id, Color(sticker.ink)),
      ),
    };
    return SizedBox(
      width: width,
      height: height,
      // With the lights off a sticker dims like the paper next to it.
      child: night
          ? ColorFiltered(
              colorFilter: const ColorFilter.mode(
                AppColors.nightShade,
                BlendMode.srcATop,
              ),
              child: art,
            )
          : art,
    );
  }
}

/// A rubber stamp: the word in heavy capitals inside a double rule, inked
/// a little unevenly.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.text, required this.ink, required this.height});

  final String text;
  final Color ink;
  final double height;

  @override
  Widget build(BuildContext context) {
    final line = math.max(2.0, height * 0.07);
    return Opacity(
      opacity: 0.86,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: ink, width: line),
          borderRadius: BorderRadius.circular(height * 0.16),
        ),
        padding: EdgeInsets.all(line * 0.9),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: ink, width: line * 0.45),
            borderRadius: BorderRadius.circular(height * 0.1),
          ),
          padding: EdgeInsets.symmetric(horizontal: height * 0.12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: height * 0.42,
                fontWeight: FontWeight.w900,
                letterSpacing: height * 0.04,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Marker doodles: an arrow, a ring drawn round something, an underline
/// swoosh and a coffee-cup ring.
class _DoodlePainter extends CustomPainter {
  const _DoodlePainter(this.id, this.ink);

  final String id;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pen = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.055;
    switch (id) {
      case 'arrow':
        final shaft = Path()
          ..moveTo(w * 0.12, h * 0.78)
          ..quadraticBezierTo(w * 0.22, h * 0.25, w * 0.82, h * 0.3);
        canvas.drawPath(shaft, pen);
        final head = Path()
          ..moveTo(w * 0.62, h * 0.14)
          ..lineTo(w * 0.84, h * 0.3)
          ..lineTo(w * 0.64, h * 0.48);
        canvas.drawPath(head, pen);
      case 'circle':
        // Round once and a little past the start, as a hand does.
        final ring = Path();
        const turns = 1.15;
        for (var i = 0; i <= 60; i++) {
          final t = i / 60 * turns * 2 * math.pi;
          final r = 0.42 + 0.03 * math.sin(t * 1.7);
          final p = Offset(
            w * (0.5 + r * math.cos(t - 0.6)),
            h * (0.5 + r * 0.72 * math.sin(t - 0.6)),
          );
          i == 0 ? ring.moveTo(p.dx, p.dy) : ring.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(ring, pen);
      case 'underline':
        final swoosh = Path()
          ..moveTo(w * 0.06, h * 0.52)
          ..cubicTo(w * 0.35, h * 0.44, w * 0.65, h * 0.6, w * 0.94, h * 0.46)
          ..moveTo(w * 0.14, h * 0.66)
          ..cubicTo(w * 0.4, h * 0.58, w * 0.62, h * 0.7, w * 0.86, h * 0.62);
        canvas.drawPath(swoosh, pen);
      case 'mai':
      case 'dao':
        // A five-petalled blossom, as on a Tết branch.
        final petal = Paint()..color = ink;
        final centre = Offset(w / 2, h / 2);
        for (var i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * 2 * math.pi / 5;
          canvas.drawCircle(
            centre + Offset(math.cos(a), math.sin(a)) * w * 0.2,
            w * 0.17,
            petal,
          );
        }
        canvas
          ..drawCircle(
            centre,
            w * 0.1,
            Paint()..color = const Color(0xFFFFF3C4),
          )
          ..drawCircle(
            centre,
            w * 0.1,
            Paint()
              ..color = const Color(0xFFB71C1C)
              ..style = PaintingStyle.stroke
              ..strokeWidth = w * 0.02,
          );
      case 'starlantern':
        // A star lantern (đèn ông sao) on its stick.
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5;
          final r = i.isEven ? w * 0.36 : w * 0.15;
          final p = Offset(w / 2 + r * math.cos(a), h * 0.44 + r * math.sin(a));
          i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
        }
        star.close();
        canvas
          ..drawLine(
            Offset(w * 0.5, h * 0.62),
            Offset(w * 0.62, h * 0.96),
            Paint()
              ..color = const Color(0xFF6D4C41)
              ..strokeWidth = w * 0.035
              ..strokeCap = StrokeCap.round,
          )
          ..drawPath(star, Paint()..color = const Color(0xFFFFCA28))
          ..drawPath(star, pen..strokeWidth = w * 0.04);
      case 'ring':
        // A mug's ring: thick on one side where the coffee pooled.
        final centre = Offset(w / 2, h / 2);
        for (var i = 0; i < 36; i++) {
          final a = i / 36 * 2 * math.pi;
          final b = (i + 1) / 36 * 2 * math.pi;
          pen.strokeWidth = w * (0.025 + 0.04 * (0.5 + 0.5 * math.cos(a - 1)));
          canvas.drawArc(
            Rect.fromCircle(center: centre, radius: w * 0.38),
            a,
            b - a,
            false,
            pen,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter oldDelegate) =>
      oldDelegate.id != id || oldDelegate.ink != ink;
}

/// The sticker sheet: every sticker, Pro ones marked. Returns the id picked,
/// or null. A Pro sticker without Pro opens the Pro sheet instead.
Future<String?> showStickerPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _StickerPicker(current: current),
  );
}

class _StickerPicker extends StatelessWidget {
  const _StickerPicker({this.current});

  final String? current;

  /// "Until 21 Feb" while a pack is open, "Back 12 Jan – 21 Feb" while it
  /// waits; nothing for everyday stickers.
  String? _seasonNote(BuildContext context, StickerPack pack) {
    final season = pack.season;
    if (season == null) return null;
    final window = currentOrNextSeason(season);
    if (window == null) return null;
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    return pack.inSeason
        ? l10n.seasonUntil(dates.formatShortMonthDay(window.end))
        : l10n.seasonBack(
            dates.formatShortMonthDay(window.start),
            dates.formatShortMonthDay(window.end),
          );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pro = ProScope.unlockedOf(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.stickerPick,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, color: AppColors.ink),
              ),
              for (final pack in StickerPack.values) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                  child: Text.rich(
                    TextSpan(
                      text: stickerPackLabel(l10n, pack),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                      children: [
                        if (_seasonNote(context, pack) case final note?)
                          TextSpan(
                            text: '  ·  $note',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: AppColors.inkSoft,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Out of season a pack waits, named, with its dates.
                if (pack.inSeason)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final sticker in stickers.where(
                        (s) => s.pack == pack,
                      ))
                        _StickerTile(
                          sticker: sticker,
                          selected: sticker.id == current,
                          locked: sticker.pro && !pro,
                          onTap: sticker.pro && !pro
                              ? () => showProSheet(context)
                              : () => Navigator.pop(context, sticker.id),
                        ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One sticker in the picker: stamps take two cells' width.
class _StickerTile extends StatelessWidget {
  const _StickerTile({
    required this.sticker,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final Sticker sticker;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stamp = sticker.kind == StickerKind.stamp;
    final label = stickerLabel(l10n, sticker);
    return Semantics(
      button: true,
      selected: selected,
      label: locked ? l10n.proLocked(label) : label,
      excludeSemantics: true,
      child: KeyboardTappable(
        onActivate: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.control),
          child: Container(
            width: stamp ? 152 : 72,
            height: 72,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadii.control),
              border: Border.all(
                color: selected ? AppColors.ink : Colors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                StickerArt(sticker: sticker, width: stamp ? 132 : 52),
                if (locked)
                  const Positioned(right: -4, top: -4, child: ProMark()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
