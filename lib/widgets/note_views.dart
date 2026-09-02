import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../services/image_service.dart';
import '../theme.dart';
import 'drawing_canvas.dart';

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
    this.onPinDragStart,
    this.onPinDragUpdate,
    this.onPinDragEnd,
  });

  final VoidCallback onEdit;
  final VoidCallback onTogglePin;
  final void Function(int index) onToggleItem;

  /// Opens the note's action sheet (edit, pin, move, share, delete).
  final VoidCallback onLongPress;

  /// Dragging *from* the pin (rather than tapping it) pulls a thread out of
  /// it; the wall view uses these to tie two notes together. Positions are
  /// global. All three are set together or not at all.
  final void Function(Offset global)? onPinDragStart;
  final void Function(Offset global)? onPinDragUpdate;
  final void Function(Offset global)? onPinDragEnd;

  bool get canDragPin => onPinDragStart != null;
}

/// An attached photo, rounded and height-capped.
class _NotePhoto extends StatelessWidget {
  const _NotePhoto({required this.path});

  final String path;
  static const double height = 120;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(ImageService.resolve(path)),
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => SizedBox(
            height: height,
            child: const Center(child: Icon(Icons.broken_image, size: 28)),
          ),
        ),
      ),
    );
  }
}

BoxDecoration paperDecoration(BuildContext context, Note note,
    {bool raised = false, bool selected = false}) {
  return BoxDecoration(
    color: paperColorOf(context, note.colorIndex, note.guid),
    borderRadius: BorderRadius.circular(AppRadii.paper),
    border: selected
        ? Border.all(color: AppColors.ink, width: 2.5)
        : null,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: raised ? 0.38 : 0.28),
        blurRadius: raised ? 16 : 7,
        offset: Offset(raised ? 4 : 2, raised ? 10 : 4),
      ),
    ],
  );
}

/// The push-pin at the top of a card; gold and larger when the note is
/// pinned, with a little bounce whenever that changes.
class NotePin extends StatefulWidget {
  const NotePin({super.key, required this.pinned});

  final bool pinned;

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
    final size = widget.pinned ? 16.0 : 12.0;
    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: widget.pinned
                ? const [Color(0xFFFFE082), Color(0xFFF9A825)]
                : const [Color(0xFFEF9A9A), Color(0xFFD32F2F)],
            center: const Alignment(-0.3, -0.3),
          ),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 3, offset: Offset(1, 2)),
          ],
        ),
      ),
    );
  }
}

/// A comfortably tappable pin: 44 wide, centered on the paper's top edge.
/// On the wall it can also be dragged to pull a thread out of it.
class _PinTarget extends StatelessWidget {
  const _PinTarget({required this.pinned, required this.cb});

  final bool pinned;
  final NoteCallbacks cb;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: pinned ? l10n.unpin : l10n.pin,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: cb.onTogglePin,
        // Being the innermost pan recognizer, this beats the card's own drag
        // and the wall's pan — so a drag that *starts* on the pin is always
        // a thread, and one that starts on the paper always moves the note.
        onPanStart: cb.canDragPin
            ? (d) => cb.onPinDragStart!(d.globalPosition)
            : null,
        onPanUpdate: cb.canDragPin
            ? (d) => cb.onPinDragUpdate!(d.globalPosition)
            : null,
        onPanEnd: cb.canDragPin
            ? (d) => cb.onPinDragEnd!(d.globalPosition)
            : null,
        onPanCancel: cb.canDragPin ? () => cb.onPinDragEnd!(Offset.zero) : null,
        child: SizedBox(
          width: 44,
          height: _pinInset * 2,
          child: Center(child: NotePin(pinned: pinned)),
        ),
      ),
    );
  }
}

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
    final label = '${ml.formatShortMonthDay(at)} '
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
    final color = overdue ? AppColors.deleteIcon : const Color(0xFF4E6E4E);

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
              Shadow(color: Colors.white54, blurRadius: 2, offset: Offset(0, 1)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (note.imagePath.isNotEmpty) _NotePhoto(path: note.imagePath),
        _content(context),
        if (hasFooter) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (note.emoji.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child:
                      Text(note.emoji, style: const TextStyle(fontSize: 22)),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body.copyWith(fontWeight: FontWeight.bold)),
              ),
            AspectRatio(
              aspectRatio: kDrawingAspect,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black12),
                ),
                child: CustomPaint(painter: StrokePainter(note.strokes)),
              ),
            ),
          ],
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
              Text(note.content,
                  style: body.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            for (var i = 0;
                i < note.checklist.length && i < maxContentLines;
                i++)
              _ChecklistRow(
                item: note.checklist[i],
                onTap: () => cb.onToggleItem(i),
              ),
            if (note.checklist.length > maxContentLines)
              Text('+${note.checklist.length - maxContentLines}…',
                  style: const TextStyle(
                      color: AppColors.inkSoft, fontSize: 14)),
          ],
        );
      case NoteType.normal:
        return Text(
          note.content,
          maxLines: maxContentLines,
          overflow: TextOverflow.ellipsis,
          style: body,
        );
    }
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.item, required this.onTap});

  final ChecklistItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 28),
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
  });

  final Note note;
  final NoteCallbacks cb;
  final bool raised;

  /// Drawn with an ink border and a check badge while multi-selecting.
  final bool selected;
  final int maxContentLines;

  /// When set, the paper (without the pin) is wrapped in a RepaintBoundary so
  /// it can be rasterized for share/save-as-image.
  final GlobalKey? captureKey;

  @override
  Widget build(BuildContext context) {
    final done = note.type == NoteType.checklist && note.checklistDone;
    Widget paper = Container(
      // Fill whatever width the wall/grid grants — the paper is a fixed-size
      // sheet, not something that shrinks to a short line of text.
      width: double.infinity,
      decoration: paperDecoration(context, note,
          raised: raised, selected: selected),
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
                    top: Radius.circular(AppRadii.paper)),
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
            padding: const EdgeInsets.fromLTRB(12, 18, 10, 10),
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
    if (done) paper = Opacity(opacity: 0.72, child: paper);
    if (captureKey != null) {
      paper = RepaintBoundary(key: captureKey, child: paper);
    }

    // Pinning straightens the note; the turn is animated so it visibly
    // "snaps" upright instead of jumping.
    return AnimatedRotation(
      turns: (note.pinned ? 0 : noteTilt(note)) / (2 * math.pi),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTap: cb.onEdit,
        onLongPress: cb.onLongPress,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Padding(padding: const EdgeInsets.only(top: _pinInset), child: paper),
            Positioned(
              top: 0,
              child: _PinTarget(pinned: note.pinned, cb: cb),
            ),
            // Sits just inside the corner, on the adhesive strip: a badge
            // hanging over the edge gets sliced off by the wall's viewport
            // when the note is pushed against the screen edge.
            if (selected)
              const Positioned(right: 3, top: _pinInset + 3, child: _SelectedBadge()),
          ],
        ),
      ),
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
      child: GestureDetector(
        onTap: cb.onEdit,
        onLongPress: cb.onLongPress,
        child: row,
      ),
    );
  }

  Widget _rowContent(BuildContext context) {
    return Row(
      children: [
        if (selected)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 11),
            child: _SelectedBadge(),
          )
        else
          _PinTarget(pinned: note.pinned, cb: cb),
        if (note.imagePath.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(File(ImageService.resolve(note.imagePath)),
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image, size: 20)),
            ),
          ),
        if (note.emoji.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(note.emoji, style: const TextStyle(fontSize: 20)),
          ),
        Expanded(child: _listContent(context)),
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
      case NoteType.drawing:
        return Row(
          children: [
            const Icon(Icons.brush, size: 18, color: AppColors.ink),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                note.content.isEmpty ? '✍️' : note.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body,
              ),
            ),
          ],
        );
      case NoteType.link:
        return Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${note.content}:', style: body),
            InkWell(
              onTap: () => openNoteUrl(context, note.url),
              child: Text(note.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _linkText(context)),
            ),
          ],
        );
      case NoteType.checklist:
        final done = note.checklist.where((i) => i.done).length;
        return Row(
          children: [
            const Icon(Icons.checklist, size: 18, color: AppColors.ink),
            const SizedBox(width: 6),
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
        return Text(note.content,
            maxLines: 2, overflow: TextOverflow.ellipsis, style: body);
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
