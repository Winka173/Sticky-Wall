import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../services/audio_service.dart';
import '../services/image_service.dart';
import '../theme.dart';
import '../util/rich_note.dart';
import 'audio_note.dart';
import 'drawing_canvas.dart';
import 'keyboard_tappable.dart';
import 'photo_frames.dart';
import 'stickers.dart';

/// The spoken name of paper colour [index] (null: the one picked from the
/// note's id), for the colour swatches.
/// Localized name of a paper ruling.
String paperStyleLabel(AppLocalizations l10n, PaperStyle style) =>
    switch (style) {
      PaperStyle.plain => l10n.paperPlain,
      PaperStyle.lined => l10n.paperLined,
      PaperStyle.grid => l10n.paperGrid,
      PaperStyle.dots => l10n.paperDots,
      PaperStyle.indexCard => l10n.paperIndex,
      PaperStyle.notebook => l10n.paperNotebook,
    };

String paperName(AppLocalizations l10n, int? index) => switch (index) {
  null => l10n.paperAuto,
  final i when isCustomPaper(i) => l10n.paperCustom,
  0 => l10n.paperYellow,
  1 => l10n.paperPink,
  2 => l10n.paperMint,
  3 => l10n.paperBlue,
  4 => l10n.paperOrange,
  5 => l10n.paperLilac,
  6 => l10n.paperLime,
  7 => l10n.paperCoral,
  8 => l10n.paperPeriwinkle,
  9 => l10n.paperSage,
  10 => l10n.paperKraft,
  11 => l10n.paperWhite,
  _ => l10n.paperAuto,
};

/// Opens [url] in the browser, defaulting to https when no scheme is given,
/// and reports failure with a snack bar.
Future<void> openNoteUrl(BuildContext context, String url) async {
  var target = url.trim();
  if (!target.startsWith(RegExp(r'https?://', caseSensitive: false))) {
    target = 'https://$target';
  }
  final uri = Uri.tryParse(target);
  var ok = false;
  if (uri != null) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpen(url))),
    );
  }
}

/// Small stable tilt (±~2°) so notes look hand-stuck, not machine-aligned.
double noteTilt(Note note, {double step = 0.008}) =>
    ((stableHash(note.guid) >> 3) % 5 - 2) * step;

/// The angle a card is drawn at on the wall, in radians: the turn the user
/// gave it with the rotate handle if any, else its hand-stuck tilt —
/// straightened while pinned. Grid and list ignore the turn (a card lying on
/// its side would collide with its neighbours) and keep only the tilt.
double noteAngle(Note note) =>
    note.rotation ?? (note.pinned ? 0 : noteTilt(note));

/// Height reserved above the paper for the pin's tap target.
const _pinInset = 14.0;

/// Callbacks shared by the card and the list tile. Deleting lives on the
/// long-press sheet (and swipe in list mode), never inline on the paper.
class NoteCallbacks {
  const NoteCallbacks({
    required this.onEdit,
    required this.onTogglePin,
    required this.onToggleItem,
    required this.onLongPress,
    this.onDoubleTap,
    this.onPinDragStart,
    this.onPinDragUpdate,
    this.onPinDragEnd,
    this.onOpenStack,
  });

  final VoidCallback onEdit;

  /// Opens the stack this card tops (its count badge); null for a lone note.
  final VoidCallback? onOpenStack;
  final VoidCallback onTogglePin;
  final void Function(int index) onToggleItem;

  /// Opens the note's action sheet (edit, pin, move, share, delete).
  final VoidCallback onLongPress;

  /// On the wall, zooms the camera onto the note (and back). Null where a
  /// double tap means nothing — then a single tap needs no wait to be sure.
  final VoidCallback? onDoubleTap;

  /// Dragging *from* the pin (rather than tapping it) pulls a thread out of
  /// it; the wall view uses these to tie two notes together. Positions are
  /// global. All three are set together or not at all.
  final void Function(Offset global)? onPinDragStart;
  final void Function(Offset global)? onPinDragUpdate;
  final void Function(Offset global)? onPinDragEnd;

  bool get canDragPin => onPinDragStart != null;
}

/// The photo attached to a note, cropped to fill its box; a broken-image
/// glyph if the file is gone. Dimmed with the lights off like the paper
/// around it.
class NotePhoto extends StatelessWidget {
  const NotePhoto({
    super.key,
    required this.path,
    this.height,
    this.maxHeight,
    this.radius = 4,
    this.semanticLabel,
  });

  final String path;

  /// What a screen reader says for the picture (a caption, or "Photo").
  /// Null keeps it silent — for a thumbnail beside words that say it all.
  final String? semanticLabel;

  /// Fixed height (cropped to it), or null with [maxHeight] to keep the
  /// photo's own aspect ratio up to that height — a print. One of the two
  /// should be set, else the image takes its natural size.
  final double? height;
  final double? maxHeight;
  final double radius;

  @override
  Widget build(BuildContext context) {
    Widget image = NightShade(
      child: Image.file(
        File(ImageService.resolve(path)),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        // A restored backup or a cleared photo folder leaves the note with a
        // name and no file: say so where there is room, not just an icon.
        errorBuilder: (context, _, _) {
          final room = (height ?? 80) >= 60;
          final words = AppLocalizations.of(context)?.photoMissing;
          return Container(
            height: height ?? 80,
            color: Colors.black.withValues(alpha: 0.06),
            padding: const EdgeInsets.all(6),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: room ? 26 : 18,
                    color: AppColors.inkSoft,
                    semanticLabel: room ? null : words,
                  ),
                  if (room && words != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      words,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
    if (maxHeight != null) {
      // A floor as well as a ceiling: until the file has decoded the image
      // has no size of its own, and a print that collapsed to nothing would
      // make the card jump when the photo arrived (and hide its remove
      // button in the editor).
      image = ColoredBox(
        color: Colors.black.withValues(alpha: 0.06),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 72, maxHeight: maxHeight!),
          child: image,
        ),
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}

/// What fills the fixed slot at the start of a list row.
enum _Lead { photo, sketch, list, link, audio, sticker, emoji, none }

/// List-row thumbnail of the note's photo.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path});

  static const size = 34.0;

  final String path;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: NotePhoto(path: path, height: size),
    );
  }
}

/// A list-row thumbnail of a sketch, the height of a photo [_Thumbnail].
class _SketchThumb extends StatelessWidget {
  const _SketchThumb({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: _Thumbnail.size * kDrawingAspect,
        height: _Thumbnail.size,
        child: NightShade(
          child: DrawingSurface(strokes: note.strokes, canvas: note.canvas),
        ),
      ),
    );
  }
}

/// The paper a note is drawn on: its colour (dimmed at night; the print white
/// for a photo), a soft drop shadow that deepens while [raised] (dragging),
/// and an ink border when [selected].
BoxDecoration paperDecoration(
  BuildContext context,
  Note note, {
  bool raised = false,
  bool selected = false,
}) {
  return BoxDecoration(
    color: note.type == NoteType.photo
        ? printColorOf(context)
        : paperColorOf(context, note.colorIndex, note.guid),
    borderRadius: BorderRadius.circular(AppRadii.paper),
    border: selected ? Border.all(color: AppColors.ink, width: 2.5) : null,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: raised ? 0.38 : 0.28),
        blurRadius: raised ? 16 : 7,
        offset: Offset(raised ? 4 : 2, raised ? 10 : 4),
      ),
    ],
  );
}

/// What holds a card to the wall, in the chosen [PinStyle]: gold and a
/// little larger when the note is pinned to the top, with a bounce whenever
/// that changes.
class NotePin extends StatefulWidget {
  const NotePin({super.key, required this.pinned, this.seed = ''});

  final bool pinned;

  /// The note's id: styles that come in several colours pick one from it,
  /// so a note keeps its pin colour.
  final String seed;

  @override
  State<NotePin> createState() => _NotePinState();
}

class _NotePinState extends State<NotePin> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 60),
  ]).animate(CurvedAnimation(parent: _bounce, curve: Curves.easeOut));

  @override
  void didUpdateWidget(NotePin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pinned != widget.pinned) _bounce.forward(from: 0);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pinned = widget.pinned;
    final shade = stableHash(widget.seed);
    final look = switch (pinStyleOf(context)) {
      PinStyle.classic => _pushPin(
        pinned ? _gold : const [Color(0xFFEF9A9A), Color(0xFFD32F2F)],
      ),
      PinStyle.colorful => _pushPin(
        pinned ? _gold : _pinColors[shade % _pinColors.length],
      ),
      PinStyle.tack => _tack(pinned),
      PinStyle.washi => _washi(pinned, shade),
      PinStyle.clip => _clip(pinned),
      PinStyle.magnet => _magnet(
        pinned ? _gold : _pinColors[shade % _pinColors.length],
      ),
    };
    return ScaleTransition(scale: _scale, child: look);
  }

  static const _gold = [Color(0xFFFFE082), Color(0xFFF9A825)];

  /// Highlight and body colour of the coloured pins and magnets.
  static const _pinColors = [
    [Color(0xFFEF9A9A), Color(0xFFD32F2F)], // red
    [Color(0xFF90CAF9), Color(0xFF1565C0)], // blue
    [Color(0xFFA5D6A7), Color(0xFF2E7D32)], // green
    [Color(0xFFCE93D8), Color(0xFF6A1B9A)], // purple
    [Color(0xFFFFCC80), Color(0xFFEF6C00)], // orange
    [Color(0xFF80CBC4), Color(0xFF00695C)], // teal
  ];

  static const _dropShadow = [
    BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(1, 2)),
  ];

  /// A round plastic push-pin head.
  Widget _pushPin(List<Color> colors) {
    final size = widget.pinned ? 16.0 : 12.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: colors,
          center: const Alignment(-0.3, -0.3),
        ),
        shape: BoxShape.circle,
        boxShadow: _dropShadow,
      ),
    );
  }

  /// A flat metal thumbtack: steel, or brass when pinned to the top.
  Widget _tack(bool pinned) {
    final size = pinned ? 18.0 : 15.0;
    final (light, dark) = pinned
        ? (const Color(0xFFFFF3C4), const Color(0xFFB8892E))
        : (const Color(0xFFF5F5F5), const Color(0xFF8D8D8D));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, dark],
        ),
        border: Border.all(color: dark, width: 1.2),
        boxShadow: _dropShadow,
      ),
      child: Center(
        child: Container(
          width: size * 0.3,
          height: size * 0.3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dark.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  /// A strip of washi tape across the top edge, slightly askew.
  Widget _washi(bool pinned, int shade) {
    const tapes = [
      Color(0xB3F48FB1), // pink
      Color(0xB381D4FA), // sky
      Color(0xB3A5D6A7), // green
      Color(0xB3FFCC80), // apricot
      Color(0xB3B39DDB), // lavender
    ];
    final color = pinned
        ? const Color(0xCCFFD54F)
        : tapes[shade % tapes.length];
    final tilt = ((shade >> 4) % 9 - 4) * 0.025;
    return Transform.rotate(
      angle: tilt,
      child: CustomPaint(
        size: Size(pinned ? 42 : 38, pinned ? 16 : 14),
        painter: _WashiPainter(color: color, dots: shade.isEven),
      ),
    );
  }

  /// A wire paper clip over the top edge: steel, or gold when pinned.
  Widget _clip(bool pinned) {
    return CustomPaint(
      size: const Size(12, 26),
      painter: _ClipPainter(
        color: pinned ? const Color(0xFFD4A017) : const Color(0xFF8A8F96),
      ),
    );
  }

  /// A round fridge magnet: larger and flatter than a push-pin.
  Widget _magnet(List<Color> colors) {
    final size = widget.pinned ? 22.0 : 19.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors[1],
        border: Border.all(color: colors[0], width: 2.5),
        boxShadow: _dropShadow,
      ),
    );
  }
}

/// Translucent tape with stripes or dots and torn, zigzag ends.
class _WashiPainter extends CustomPainter {
  const _WashiPainter({required this.color, required this.dots});

  final Color color;
  final bool dots;

  @override
  void paint(Canvas canvas, Size size) {
    const tooth = 3.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0);
    for (var y = 0.0; y < size.height; y += tooth) {
      path
        ..lineTo(size.width - tooth / 2, y + tooth / 2)
        ..lineTo(size.width, math.min(y + tooth, size.height));
    }
    path.lineTo(0, size.height);
    for (var y = size.height; y > 0; y -= tooth) {
      path
        ..lineTo(tooth / 2, y - tooth / 2)
        ..lineTo(0, math.max(y - tooth, 0));
    }
    path.close();
    canvas
      ..drawShadow(path, Colors.black26, 1.5, true)
      ..drawPath(path, Paint()..color = color)
      ..save()
      ..clipPath(path);
    final pattern = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 2;
    if (dots) {
      for (var x = 5.0; x < size.width; x += 7) {
        for (var y = 3.5; y < size.height; y += 7) {
          canvas.drawCircle(Offset(x, y), 1.4, pattern);
        }
      }
    } else {
      for (var x = -size.height; x < size.width; x += 6) {
        canvas.drawLine(
          Offset(x, size.height),
          Offset(x + size.height, 0),
          pattern,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WashiPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dots != dots;
}

/// A paper clip: two nested wire loops, drawn top to bottom.
class _ClipPainter extends CustomPainter {
  const _ClipPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wire = Path()
      ..moveTo(w * 0.72, h * 0.30)
      ..lineTo(w * 0.72, h * 0.80)
      ..arcToPoint(
        Offset(w * 0.28, h * 0.80),
        radius: Radius.circular(w * 0.22),
      )
      ..lineTo(w * 0.28, h * 0.14)
      ..arcToPoint(
        Offset(w * 0.92, h * 0.14),
        radius: Radius.circular(w * 0.32),
      )
      ..lineTo(w * 0.92, h * 0.86)
      ..arcToPoint(
        Offset(w * 0.08, h * 0.86),
        radius: Radius.circular(w * 0.42),
      )
      ..lineTo(w * 0.08, h * 0.36);
    final wireShadow = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final wirePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas
      ..save()
      ..translate(0.8, 1.2)
      ..drawPath(wire, wireShadow)
      ..restore()
      ..drawPath(wire, wirePaint);
  }

  @override
  bool shouldRepaint(_ClipPainter oldDelegate) => oldDelegate.color != color;
}

/// A comfortably tappable pin: 44 wide, centered on the paper's top edge.
/// On the wall it can also be dragged to pull a thread out of it.
///
/// With [reach], a wider band reaching that far down into the paper also
/// starts a thread when dragged, so the pin is easy to grab with a thumb
/// (44 dp tall in all). Taps and long-presses in that band still go to the
/// paper underneath; only the tap target itself pins and unpins.
class _PinTarget extends StatelessWidget {
  const _PinTarget({
    required this.pinned,
    required this.cb,
    this.seed = '',
    this.reach = 0,
    this.row = false,
  });

  final bool pinned;
  final NoteCallbacks cb;
  final String seed;
  final double reach;

  /// In a list row there is room for a full 48 x 48 target. On a card the
  /// target stays 44 x 28 so a tap on the top of the paper still opens the
  /// note; screen readers get Pin as an action of the card instead (see
  /// [NoteCard]), so this small button is left out of their tree.
  final bool row;

  /// Width of the drag-only band around the tap target.
  static const _grabWidth = 64.0;

  @override
  Widget build(BuildContext context) {
    final pin = _tapTarget(context);
    if (reach <= 0 || !cb.canDragPin) return pin;
    return _threadDrag(
      // Translucent: a tap or long-press here falls through to the paper.
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: _grabWidth,
        height: _pinInset * 2 + reach,
        child: Align(alignment: Alignment.topCenter, child: pin),
      ),
    );
  }

  /// Wraps [child] so a drag on it pulls a thread. The pin's recognizer takes
  /// the finger after a few pixels: the card's own drag and the wall's pan
  /// wait for much more, so a drag that *starts* on the pin is always a
  /// thread, and one that starts lower on the paper moves the note.
  Widget _threadDrag({
    required HitTestBehavior behavior,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return RawGestureDetector(
      behavior: behavior,
      gestures: {
        if (onTap != null)
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (r) => r.onTap = onTap,
              ),
        if (cb.canDragPin)
          _PinDragRecognizer:
              GestureRecognizerFactoryWithHandlers<_PinDragRecognizer>(
                _PinDragRecognizer.new,
                (r) {
                  r.onStart = (d) => cb.onPinDragStart!(d.globalPosition);
                  r.onUpdate = (d) => cb.onPinDragUpdate!(d.globalPosition);
                  r.onEnd = (d) => cb.onPinDragEnd!(d.globalPosition);
                  r.onCancel = () => cb.onPinDragEnd!(Offset.zero);
                },
              ),
      },
      child: child,
    );
  }

  Widget _tapTarget(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return KeyboardTappable(
      onActivate: cb.onTogglePin,
      circle: true,
      child: Semantics(
        button: true,
        toggled: pinned,
        label: pinned ? l10n.unpin : l10n.pin,
        excludeSemantics: !row,
        child: _threadDrag(
          behavior: HitTestBehavior.opaque,
          onTap: cb.onTogglePin,
          child: SizedBox(
            width: row ? 48 : 44,
            height: row ? 48 : _pinInset * 2,
            child: Center(
              child: NotePin(pinned: pinned, seed: seed),
            ),
          ),
        ),
      ),
    );
  }
}

/// The drag that pulls a thread out of a pin. It takes the gesture after a
/// few pixels, well before the card's drag (about 29px) and the wall's pan,
/// which a plain pan recognizer (36px) would lose to.
class _PinDragRecognizer extends PanGestureRecognizer {
  _PinDragRecognizer() {
    dragStartBehavior = DragStartBehavior.down;
  }

  static const double _slop = 6;

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) => globalDistanceMoved.abs() > _slop;
}

/// Small pill showing the next reminder time; red once it is overdue.
class _ReminderChip extends StatelessWidget {
  const _ReminderChip({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final at = note.nextReminder()!;
    final repeats = note.repeat != ReminderRepeat.none;
    // A repeating reminder is never "overdue" — it just rings again.
    final overdue = !repeats && at.isBefore(DateTime.now());
    final ml = MaterialLocalizations.of(context);
    final label =
        '${ml.formatShortMonthDay(at)} '
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
    final color = overdue ? AppColors.warnText : const Color(0xFF2E4A2E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            repeats
                ? Icons.repeat
                : overdue
                ? Icons.alarm_on
                : Icons.alarm,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// The big tick stamped across a finished to-do list.
class _DoneStamp extends StatelessWidget {
  const _DoneStamp();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Transform.rotate(
          angle: -0.25,
          child: Icon(
            Icons.check_rounded,
            size: 72,
            color: const Color(0xFF2E7D32).withValues(alpha: 0.55),
            shadows: const [
              Shadow(
                color: Colors.white54,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small ink check badge in the corner of a selected note.
class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: AppColors.ink,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: const Icon(Icons.check, size: 15, color: AppColors.chalk),
    );
  }
}

/// Body style for a link note's URL: blue and underlined.
TextStyle _linkText(BuildContext context) => noteBodyStyle(context).copyWith(
  color: AppColors.link,
  decoration: TextDecoration.underline,
  decorationColor: AppColors.link,
);

/// The body of a note (everything but the pin): type-specific content plus,
/// when present, an emote and a reminder chip.
class _NoteBody extends StatelessWidget {
  const _NoteBody({
    required this.note,
    required this.cb,
    required this.maxContentLines,
  });

  final Note note;
  final NoteCallbacks cb;
  final int maxContentLines;

  @override
  Widget build(BuildContext context) {
    final hasFooter = note.emoji.isNotEmpty || note.reminderAt != null;
    // A photo print draws its picture itself; here it would double up.
    final showPhoto = note.hasPhoto && note.type != NoteType.photo;
    // A print or sketch without a caption has no text above the footer, so
    // no gap either.
    final hasText = note.content.isNotEmpty || note.type == NoteType.checklist;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPhoto)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NotePhoto(path: note.imagePath, height: 120),
          ),
        _content(context),
        if (hasFooter) ...[
          if (hasText) const SizedBox(height: 6),
          Row(
            children: [
              if (note.emoji.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(note.emoji, style: const TextStyle(fontSize: 22)),
                ),
              if (note.reminderAt != null)
                // Expanded + Align: the chip takes only the width it needs but
                // may shrink (and ellipsize) on a narrow card.
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _ReminderChip(note: note),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _content(BuildContext context) {
    final body = noteBodyStyle(context);
    switch (note.type) {
      case NoteType.drawing:
        // The sketch itself is the card (see StickyNoteCard._sketch); this is
        // only the title written on the label strip under it.
        if (note.content.isEmpty) return const SizedBox.shrink();
        return Text(
          note.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: body.copyWith(fontWeight: FontWeight.bold),
        );
      case NoteType.link:
        return InkWell(
          onTap: () => openNoteUrl(context, note.url),
          child: Text(
            note.content,
            maxLines: maxContentLines,
            overflow: TextOverflow.ellipsis,
            style: _linkText(context),
          ),
        );
      case NoteType.checklist:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note.content.isNotEmpty)
              Text(
                note.content,
                style: body.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            for (
              var i = 0;
              i < note.checklist.length && i < maxContentLines;
              i++
            )
              _ChecklistRow(
                item: note.checklist[i],
                onTap: () => cb.onToggleItem(i),
              ),
            if (note.checklist.length > maxContentLines)
              Text(
                '+${note.checklist.length - maxContentLines}…',
                style: const TextStyle(color: AppColors.inkSoft, fontSize: 14),
              ),
          ],
        );
      case NoteType.normal:
        return Text.rich(
          TextSpan(style: body, children: noteSpans(note.content, body)),
          maxLines: maxContentLines,
          overflow: TextOverflow.ellipsis,
        );
      case NoteType.label:
        return Text(
          note.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: body.copyWith(fontWeight: FontWeight.bold),
        );
      case NoteType.sticker:
        return const SizedBox.shrink();
      case NoteType.audio:
        // The cassette writes its title on its own label sticker.
        if (note.content.isEmpty) return const SizedBox.shrink();
        return Text(
          note.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: body.copyWith(fontWeight: FontWeight.bold),
        );
      case NoteType.photo:
        // The caption written under a print; nothing at all when blank.
        if (note.content.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          width: double.infinity,
          child: Text(
            note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: body.copyWith(fontSize: body.fontSize! * 0.92),
          ),
        );
    }
  }
}

/// One checklist line: a tappable box and the item text, struck through when
/// done.
class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.item, required this.onTap});

  final ChecklistItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // One node: "Milk, checked" — not an unnamed tap target beside a line
    // of text.
    return MergeSemantics(
      child: Semantics(
        checked: item.done,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    item.done ? Icons.check_box : Icons.check_box_outline_blank,
                    key: ValueKey(item.done),
                    size: 18,
                    color: AppColors.ink.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: item.done ? AppColors.inkSoft : AppColors.ink,
                      decoration: item.done ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A pinned sticky note used by both the wall and grid views.
class StickyNoteCard extends StatelessWidget {
  const StickyNoteCard({
    super.key,
    required this.note,
    required this.cb,
    this.raised = false,
    this.selected = false,
    this.maxContentLines = 6,
    this.captureKey,
    this.rotated = true,
    this.stackCount = 1,
  });

  /// How many notes lie in this card's pile, itself included. Above one the
  /// card draws the sheets under it peeking out, and a count to open them.
  final int stackCount;

  final Note note;
  final NoteCallbacks cb;
  final bool raised;

  /// Drawn with an ink border and a check badge while multi-selecting.
  final bool selected;
  final int maxContentLines;

  /// When set, the paper (without the pin) is wrapped in a RepaintBoundary so
  /// it can be rasterized for share/save-as-image.
  final GlobalKey? captureKey;

  /// Whether the card gives itself its hand-stuck tilt (see [noteTilt]). The
  /// wall passes false and turns the card by [noteAngle] together with its
  /// handles (see [NoteTurn]), so they stay on its corners whichever way it
  /// faces.
  final bool rotated;

  @override
  Widget build(BuildContext context) {
    final done = note.type == NoteType.checklist && note.checklistDone;
    Widget paper = switch (note.type) {
      NoteType.photo => _print(context),
      NoteType.drawing => _sketch(context),
      NoteType.label => _tape(context),
      NoteType.audio => _cassette(context),
      NoteType.sticker => _stickerArt(),
      _ => _sheet(context, done),
    };
    if (done) paper = Opacity(opacity: 0.72, child: paper);
    if (stackCount > 1) paper = _pile(context, paper);
    if (captureKey != null) {
      paper = RepaintBoundary(key: captureKey, child: paper);
    }

    final card = GestureDetector(
      onTap: cb.onEdit,
      onDoubleTap: cb.onDoubleTap,
      onLongPress: cb.onLongPress,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: _pinInset),
            child: paper,
          ),
          // Tape and stickers are stuck down flat: no pin (so no thread can
          // start from them either; one can still end on them).
          if (note.type != NoteType.label && note.type != NoteType.sticker)
            Positioned(
              top: 0,
              child: _PinTarget(
                pinned: note.pinned,
                cb: cb,
                seed: note.guid,
                reach: 16,
              ),
            ),
          if (note.locked)
            Positioned(
              left: 5,
              top: _pinInset + 4,
              child: Icon(
                // Fixed in place: an anchor (a padlock means a locked board).
                Icons.anchor,
                size: 12,
                color: AppColors.inkSoft,
                semanticLabel: AppLocalizations.of(context)?.locked,
              ),
            ),
          // Sits just inside the corner, on the adhesive strip: a badge
          // hanging over the edge gets sliced off by the wall's viewport
          // when the note is pushed against the screen edge.
          if (selected)
            const Positioned(
              right: 3,
              top: _pinInset + 3,
              child: _SelectedBadge(),
            ),
        ],
      ),
    );
    // From a keyboard: Enter opens the note, Shift+F10 its menu. A screen
    // reader also finds Pin / Unpin among the card's actions.
    final l10n = AppLocalizations.of(context)!;
    final pinnable =
        note.type != NoteType.label && note.type != NoteType.sticker;
    final said = Semantics(
      selected: selected,
      customSemanticsActions: pinnable
          ? {
              CustomSemanticsAction(label: note.pinned ? l10n.unpin : l10n.pin):
                  cb.onTogglePin,
            }
          : null,
      child: KeyboardTappable(
        onActivate: cb.onEdit,
        onMenu: cb.onLongPress,
        child: card,
      ),
    );
    if (!rotated) return said;
    return NoteTurn(angle: note.pinned ? 0 : noteTilt(note), child: said);
  }

  /// The card on top of its stack: two sheets of the pile peek out below
  /// and to the side, a little askew, and a count on the corner opens them.
  Widget _pile(BuildContext context, Widget paper) {
    final under = paperColorOf(context, note.colorIndex, note.guid);
    Widget sheet(double dx, double dy, double turn) => Positioned.fill(
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: turn,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(under, Colors.black, 0.12),
              borderRadius: BorderRadius.circular(AppRadii.paper),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final l10n = AppLocalizations.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (stackCount > 2) sheet(10, 10, 0.04),
        sheet(5, 6, -0.03),
        paper,
        // Top right: the bottom corners belong to the resize and turn grips.
        Positioned(
          right: -12,
          top: -12,
          child: Semantics(
            button: true,
            label: l10n?.stackCount(stackCount),
            excludeSemantics: true,
            child: KeyboardTappable(
              circle: true,
              onActivate: cb.onOpenStack,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: cb.onOpenStack,
                child: SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 26),
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AppColors.chalk, width: 1.5),
                      ),
                      child: Text(
                        '$stackCount',
                        style: const TextStyle(
                          color: AppColors.chalk,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Where the writing on a sheet starts.
  static const _bodyTop = 18.0;

  /// The note text's real line height and where its first line's rule goes
  /// (just under the baseline), measured in the chosen font at the reader's
  /// text size, so ruled paper follows the writing whatever the font.
  ({double line, double firstRule}) _rulesFor(BuildContext context) {
    final style = DefaultTextStyle.of(
      context,
    ).style.merge(noteBodyStyle(context));
    final probe = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final metrics = probe.computeLineMetrics().first;
    probe.dispose();
    return (line: metrics.height, firstRule: metrics.baseline + 3);
  }

  /// A sticker stuck straight on the wall, centred in the card's width:
  /// emoji and doodles at about two thirds of it, stamps nearly all of it.
  Widget _stickerArt() {
    final sticker = stickerById(note.sticker);
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 160.0;
        // Stamps and tapes run long and low; the rest sit smaller.
        final long =
            sticker.kind == StickerKind.stamp ||
            (sticker.kind == StickerKind.image && sticker.aspect < 0.6);
        final width = room * (long ? 0.95 : 0.62);
        return Container(
          width: double.infinity,
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  border: Border.all(color: AppColors.ink, width: 2.5),
                  borderRadius: BorderRadius.circular(AppRadii.control),
                )
              : null,
          child: Semantics(
            label: stickerLabel(AppLocalizations.of(context)!, sticker),
            child: StickerArt(sticker: sticker, width: width),
          ),
        );
      },
    );
  }

  /// A sheet of sticky paper: adhesive strip, curled corner, the body.
  Widget _sheet(BuildContext context, bool done) {
    // A paper that does not suit the note (lines on a list, after its type
    // changed) is shown plain rather than ruled across its rows.
    final paper = note.paper.suits(note.type) ? note.paper : PaperStyle.plain;
    final notebook = paper == PaperStyle.notebook;
    final rules = paper == PaperStyle.plain ? null : _rulesFor(context);
    return Container(
      // Fill whatever width the wall/grid grants — the paper is a fixed-size
      // sheet, not something that shrinks to a short line of text.
      width: double.infinity,
      decoration: paperDecoration(
        context,
        note,
        raised: raised,
        selected: selected,
      ),
      child: Stack(
        children: [
          // Adhesive strip along the top, like a real sticky note.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x21FFFFFF),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadii.paper),
                ),
              ),
            ),
          ),
          // Lines, squares or dots printed on the paper, under the writing.
          if (rules != null)
            Positioned.fill(
              child: CustomPaint(
                painter: PaperPatternPainter(
                  paper,
                  line: rules.line,
                  first: _bodyTop + rules.firstRule,
                ),
              ),
            ),
          // Slightly curled corner.
          Positioned(
            right: 0,
            bottom: 0,
            child: CustomPaint(
              size: const Size(16, 16),
              painter: _FoldCornerPainter(),
            ),
          ),
          Padding(
            // A notebook page writes right of its red margin.
            padding: EdgeInsets.fromLTRB(notebook ? 30 : 12, _bodyTop, 10, 10),
            child: _NoteBody(
              note: note,
              cb: cb,
              maxContentLines: maxContentLines,
            ),
          ),
          // A finished list fades a little and gets a big tick, so it reads
          // as "done" from across the room.
          if (done) const Positioned.fill(child: _DoneStamp()),
        ],
      ),
    );
  }

  /// A label: a strip of tape with a word or two written on it, to name a
  /// column or a corner of the wall. Stuck down flat — no pin, no adhesive
  /// strip, no curled corner.
  Widget _tape(BuildContext context) {
    final color = paperColorOf(context, note.colorIndex, note.guid);
    final body = noteBodyStyle(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(2),
        border: selected ? Border.all(color: AppColors.ink, width: 2.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: raised ? 0.30 : 0.18),
            blurRadius: raised ? 10 : 4,
            offset: Offset(1, raised ? 5 : 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: CustomPaint(
          painter: const _TapePainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
            child: Row(
              children: [
                if (note.emoji.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      note.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                Expanded(
                  child: Text(
                    note.content,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: body.copyWith(
                      fontSize: body.fontSize! * 1.15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A photo print: the picture at its own aspect ratio inside a narrow white
  /// border, with the caption (and emote / reminder) written underneath like
  /// on the back of a snapshot. No adhesive strip or curled corner — it's
  /// glossy paper.
  Widget _print(BuildContext context) {
    final hasCaption =
        note.content.isNotEmpty ||
        note.emoji.isNotEmpty ||
        note.reminderAt != null;
    if (note.frame != PhotoFrame.print) {
      return FramedPrint(
        frame: note.frame,
        seed: note.guid,
        paper: paperColorOf(context, note.colorIndex, note.guid),
        selected: selected,
        raised: raised,
        photo: NotePhoto(
          path: note.imagePath,
          maxHeight: 230,
          radius: 0,
          semanticLabel: hasCaption
              ? null
              : AppLocalizations.of(context)?.typePhoto,
        ),
        caption: hasCaption
            ? _NoteBody(note: note, cb: cb, maxContentLines: maxContentLines)
            : null,
      );
    }
    return Container(
      width: double.infinity,
      decoration: paperDecoration(
        context,
        note,
        raised: raised,
        selected: selected,
      ),
      // A touch more room at the top so the pin head lands on the border,
      // not through the picture.
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NotePhoto(
            path: note.imagePath,
            maxHeight: 230,
            radius: 2,
            // A caption below is read on its own; only a bare print needs
            // a name here.
            semanticLabel: hasCaption
                ? null
                : AppLocalizations.of(context)?.typePhoto,
          ),
          if (hasCaption)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
              child: _NoteBody(
                note: note,
                cb: cb,
                maxContentLines: maxContentLines,
              ),
            ),
        ],
      ),
    );
  }

  /// A voice note: a little cassette in the note's paper colour — screws in
  /// the corners, a cream label sticker with the title written on it and the
  /// running time in the corner like "side A, 0:42", the tape window with its
  /// two reels beside a play button, and the head notch along the bottom.
  Widget _cassette(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final body = noteBodyStyle(context);
    final shell = paperColorOf(context, note.colorIndex, note.guid);
    final length = Duration(milliseconds: note.audioMs);
    final hasFooter = note.emoji.isNotEmpty || note.reminderAt != null;
    final small = body.copyWith(
      fontSize: body.fontSize! * 0.78,
      color: AppColors.inkSoft,
    );
    final label = DecoratedBox(
      decoration: BoxDecoration(
        color: printColorOf(context),
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: CassetteLabelPainter(
          stripe: Color.lerp(shell, AppColors.ink, 0.22)!,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(7, 8, 7, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'A',
                style: small.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  note.content.isEmpty ? (l10n?.typeAudio ?? '') : note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: note.content.isEmpty
                      ? body.copyWith(color: AppColors.inkSoft)
                      : body.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (note.audioMs > 0) ...[
                const SizedBox(width: 4),
                PlaybackCounter(
                  stored: note.audioPath,
                  length: length,
                  style: small,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Container(
      width: double.infinity,
      decoration: paperDecoration(
        context,
        note,
        raised: raised,
        selected: selected,
      ).copyWith(borderRadius: BorderRadius.circular(6)),
      child: CustomPaint(
        painter: const CassetteShellPainter(notch: 11),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 12, 11, 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              label,
              const SizedBox(height: 6),
              Row(
                children: [
                  VoicePlayButton(stored: note.audioPath),
                  const SizedBox(width: 4),
                  Expanded(
                    child: PlaybackTape(
                      stored: note.audioPath,
                      length: length,
                      height: 30,
                    ),
                  ),
                ],
              ),
              if (hasFooter)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      if (note.emoji.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            note.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      if (note.reminderAt != null)
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _ReminderChip(note: note),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// A sketch: the drawing *is* the paper, edge to edge, rather than a framed
  /// thumbnail with margins around it. A title, emote or reminder sits on a
  /// strip of the note's sticky paper underneath, like the label under a
  /// framed picture; with none of those the doodle fills the whole card.
  Widget _sketch(BuildContext context) {
    final hasLabel =
        note.content.isNotEmpty ||
        note.emoji.isNotEmpty ||
        note.reminderAt != null;
    return Container(
      width: double.infinity,
      decoration: paperDecoration(
        context,
        note,
        raised: raised,
        selected: selected,
      ),
      child: ClipRRect(
        // The selection border insets the child, so it clips a hair tighter
        // and tucks under the corners of the frame.
        borderRadius: BorderRadius.circular(
          AppRadii.paper - (selected ? 2 : 0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: kDrawingAspect,
              child: Semantics(
                image: true,
                label: hasLabel
                    ? null
                    : AppLocalizations.of(context)?.typeDrawing,
                child: NightShade(
                  child: DrawingSurface(
                    strokes: note.strokes,
                    canvas: note.canvas,
                  ),
                ),
              ),
            ),
            if (hasLabel)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: _NoteBody(
                  note: note,
                  cb: cb,
                  maxContentLines: maxContentLines,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Faint diagonal stripes, so tape reads as tape and not as a flat colour.
class _TapePainter extends CustomPainter {
  const _TapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stripe = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 3;
    for (var x = -size.height; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
    // The torn ends: a lighter sliver where the tape was pulled off the roll.
    final end = Paint()..color = Colors.white.withValues(alpha: 0.28);
    canvas.drawRect(Rect.fromLTWH(0, 0, 3, size.height), end);
    canvas.drawRect(Rect.fromLTWH(size.width - 3, 0, 3, size.height), end);
  }

  @override
  bool shouldRepaint(_TapePainter oldDelegate) => false;
}

/// Turns a card by [angle] (radians, clockwise) about its centre. The turn is
/// animated so pinning visibly "snaps" the note upright and a tidy-up
/// straightens it smoothly instead of jumping — except while [live], when the
/// user's finger is on the rotate handle and the card must follow it exactly.
class NoteTurn extends StatelessWidget {
  const NoteTurn({
    super.key,
    required this.angle,
    required this.child,
    this.live = false,
  });

  final double angle;
  final Widget child;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: angle / (2 * math.pi),
      duration: live ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: child,
    );
  }
}

/// Dims [child] the way note paper is dimmed with the lights off, so a bright
/// sketch or photo doesn't glow among the shaded notes at night. Invisible by
/// day.
class NightShade extends StatelessWidget {
  const NightShade({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isNight(context)) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        const Positioned.fill(
          child: IgnorePointer(child: ColoredBox(color: AppColors.nightShade)),
        ),
      ],
    );
  }
}

/// A subtle darkening gradient in the bottom-right corner that reads as a
/// slightly curled page corner.
class _FoldCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.transparent, Color(0x2E000000)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      Paint()
        ..color = const Color(0x14000000)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_FoldCornerPainter oldDelegate) => false;
}

/// A compact full-width row for list mode.
class NoteListTile extends StatelessWidget {
  const NoteListTile({
    super.key,
    required this.note,
    required this.cb,
    this.selected = false,
    this.captureKey,
  });

  final Note note;
  final NoteCallbacks cb;
  final bool selected;
  final GlobalKey? captureKey;

  @override
  Widget build(BuildContext context) {
    Widget row = Container(
      decoration: paperDecoration(context, note, selected: selected),
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      child: _rowContent(context),
    );
    if (captureKey != null) {
      row = RepaintBoundary(key: captureKey, child: row);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: KeyboardTappable(
        onActivate: cb.onEdit,
        onMenu: cb.onLongPress,
        borderRadius: BorderRadius.circular(AppRadii.paper),
        child: GestureDetector(
          onTap: cb.onEdit,
          onLongPress: cb.onLongPress,
          child: row,
        ),
      ),
    );
  }

  _Lead get _leadingKind => note.hasPhoto
      ? _Lead.photo
      : note.type == NoteType.drawing
      ? _Lead.sketch
      : note.type == NoteType.checklist
      ? _Lead.list
      : note.type == NoteType.link
      ? _Lead.link
      : note.type == NoteType.audio
      ? _Lead.audio
      : note.type == NoteType.sticker
      ? _Lead.sticker
      : note.emoji.isNotEmpty
      ? _Lead.emoji
      : _Lead.none;

  /// One fixed-width slot before the words — photo, sketch, list or link
  /// icon, or the emote — so every row's text starts on the same edge.
  Widget _leading() {
    final child = switch (_leadingKind) {
      _Lead.photo => _Thumbnail(path: note.imagePath),
      _Lead.sketch => _SketchThumb(note: note),
      _Lead.list => const Icon(Icons.checklist, size: 20, color: AppColors.ink),
      _Lead.link => const Icon(Icons.link, size: 20, color: AppColors.ink),
      _Lead.audio => const Icon(
        Icons.voicemail,
        size: 22,
        color: AppColors.ink,
      ),
      _Lead.sticker => StickerArt(
        sticker: stickerById(note.sticker),
        width: _slot,
      ),
      _Lead.emoji => Text(note.emoji, style: const TextStyle(fontSize: 20)),
      _Lead.none => null,
    };
    // A narrow slot: a wide sketch shrinks into it rather than pushing
    // every plain row's words a third of the way across.
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: _slot,
        height: _Thumbnail.size,
        child: child == null
            ? null
            : FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
  }

  static const _slot = 40.0;

  Widget _rowContent(BuildContext context) {
    return Row(
      children: [
        if (selected)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 11),
            child: _SelectedBadge(),
          )
        else if (note.type == NoteType.label)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 13),
            child: Icon(Icons.label, size: 18, color: AppColors.inkSoft),
          )
        else if (note.type == NoteType.sticker)
          const SizedBox(width: 44)
        else
          _PinTarget(pinned: note.pinned, cb: cb, seed: note.guid, row: true),
        _leading(),
        if (note.emoji.isNotEmpty && _leadingKind != _Lead.emoji)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(note.emoji, style: const TextStyle(fontSize: 20)),
          ),
        Expanded(child: _listContent(context)),
        if (note.type == NoteType.audio && note.hasAudio)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: VoicePlayButton(stored: note.audioPath, size: 36),
          ),
        if (note.reminderAt != null)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: _ReminderChip(note: note),
            ),
          ),
      ],
    );
  }

  Widget _listContent(BuildContext context) {
    final body = noteBodyStyle(context);
    switch (note.type) {
      case NoteType.photo:
        // The thumbnail already shows the picture; an uncaptioned print just
        // gets the type name, in soft ink, like an untitled sketch.
        return note.content.isEmpty
            ? Text(
                AppLocalizations.of(context)!.typePhoto,
                style: body.copyWith(color: AppColors.inkSoft),
              )
            : Text(
                note.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body,
              );
      case NoteType.drawing:
        // The thumbnail already says "sketch"; an untitled one just gets the
        // type name, in soft ink.
        return note.content.isEmpty
            ? Text(
                AppLocalizations.of(context)!.typeDrawing,
                style: body.copyWith(color: AppColors.inkSoft),
              )
            : Text(
                note.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body,
              );
      case NoteType.label:
        return Text(
          note.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: body.copyWith(fontWeight: FontWeight.bold),
        );
      case NoteType.sticker:
        final l10n = AppLocalizations.of(context)!;
        final sticker = stickerById(note.sticker);
        return Text(
          sticker.kind == StickerKind.emoji
              ? l10n.typeSticker
              : stickerLabel(l10n, sticker),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: body.copyWith(color: AppColors.inkSoft),
        );
      case NoteType.audio:
        // The title (or the type name, in soft ink) and the running time.
        final name = note.content.isEmpty
            ? AppLocalizations.of(context)!.typeAudio
            : note.content;
        return Text(
          note.audioMs > 0
              ? '$name · ${formatClip(Duration(milliseconds: note.audioMs))}'
              : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: note.content.isEmpty
              ? body.copyWith(color: AppColors.inkSoft)
              : body,
        );
      case NoteType.link:
        return Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${note.content}:', style: body),
            InkWell(
              onTap: () => openNoteUrl(context, note.url),
              child: Text(
                note.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _linkText(context),
              ),
            ),
          ],
        );
      case NoteType.checklist:
        final done = note.checklist.where((i) => i.done).length;
        return Row(
          children: [
            Expanded(
              child: Text(
                note.content.isEmpty
                    ? '($done/${note.checklist.length})'
                    : '${note.content}  ($done/${note.checklist.length})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body,
              ),
            ),
          ],
        );
      case NoteType.normal:
        return Text.rich(
          TextSpan(style: body, children: noteSpans(note.content, body)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    }
  }
}

/// Plays a small "stick onto the wall" entrance: fade in while settling down
/// onto the surface. [delay] staggers a batch (grid, wall) so notes land one
/// after another instead of popping in all at once.
class NoteAppear extends StatefulWidget {
  const NoteAppear({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<NoteAppear> createState() => _NoteAppearState();
}

class _NoteAppearState extends State<NoteAppear>
    with SingleTickerProviderStateMixin {
  static const _play = Duration(milliseconds: 300);

  // One controller covers delay + play; the Interval curve holds the note
  // invisible during the delay. No Timer, so tests and disposal stay clean.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.delay + _play,
  )..forward();

  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay.inMilliseconds / (widget.delay + _play).inMilliseconds,
      1.0,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - v)),
            child: Transform.scale(scale: 0.96 + 0.04 * v, child: child),
          ),
        );
      },
    );
  }
}

/// The ruling printed on a sheet of note paper ([PaperStyle]): lines one
/// [line] apart under each line of writing, a grid or dots at half that, an
/// index card's red heading rule, or a notebook page's red margin and holes.
class PaperPatternPainter extends CustomPainter {
  const PaperPatternPainter(
    this.style, {
    required this.line,
    this.top = 18,
    this.first,
    this.margin = true,
  });

  final PaperStyle style;

  /// Height of one line of note text.
  final double line;

  /// Where the writing starts.
  final double top;

  /// Where the first rule goes, when the caller has measured it; otherwise
  /// just under a typical first line below [top].
  final double? first;

  /// Whether a notebook page draws its red margin and punched holes (the
  /// editor, whose text runs from the left edge, leaves them out).
  final bool margin;

  static const _blue = Color(0x4D1E63C6);
  static const _red = Color(0x80D32F2F);

  @override
  void paint(Canvas canvas, Size size) {
    if (line <= 0) return;
    final ink = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    // Just under the first line's letters, and every line after.
    final first = this.first ?? top + line * 0.88;
    void rules(Paint paint, {double from = 0}) {
      for (var y = first; y < size.height - 6; y += line) {
        canvas.drawLine(Offset(from, y), Offset(size.width, y), paint);
      }
    }

    switch (style) {
      case PaperStyle.plain:
        break;
      case PaperStyle.lined:
        rules(ink);
      case PaperStyle.grid:
        final step = line / 2;
        final grid = Paint()
          ..color = AppColors.ink.withValues(alpha: 0.10)
          ..strokeWidth = 1;
        for (var y = step; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
        }
        for (var x = step; x < size.width; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
        }
      case PaperStyle.dots:
        final step = line / 2;
        final dot = Paint()..color = AppColors.ink.withValues(alpha: 0.24);
        for (var y = step; y < size.height; y += step) {
          for (var x = step; x < size.width; x += step) {
            canvas.drawCircle(Offset(x, y), 1.1, dot);
          }
        }
      case PaperStyle.indexCard:
        // The heading line in red, the rest in faint blue.
        canvas.drawLine(
          Offset(0, first),
          Offset(size.width, first),
          Paint()
            ..color = _red
            ..strokeWidth = 1.4,
        );
        for (var y = first + line; y < size.height - 6; y += line) {
          canvas.drawLine(
            Offset(0, y),
            Offset(size.width, y),
            Paint()
              ..color = _blue
              ..strokeWidth = 1,
          );
        }
      case PaperStyle.notebook:
        rules(
          Paint()
            ..color = _blue
            ..strokeWidth = 1,
        );
        if (!margin) break;
        canvas.drawLine(
          const Offset(24, 0),
          Offset(24, size.height),
          Paint()
            ..color = _red
            ..strokeWidth = 1.2,
        );
        // Punched holes down the edge.
        final hole = Paint()..color = Colors.black.withValues(alpha: 0.16);
        for (var y = line * 0.9; y < size.height - 8; y += line * 2) {
          canvas.drawCircle(Offset(10, y), 3.2, hole);
        }
    }
  }

  @override
  bool shouldRepaint(PaperPatternPainter oldDelegate) =>
      oldDelegate.style != style ||
      oldDelegate.line != line ||
      oldDelegate.top != top ||
      oldDelegate.first != first ||
      oldDelegate.margin != margin;
}
