import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../services/image_service.dart';
import '../theme.dart';
import 'drawing_canvas.dart';

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
  });

  final VoidCallback onEdit;
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
  });

  final String path;

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
        errorBuilder: (_, _, _) => Container(
          height: height ?? 80,
          color: Colors.black.withValues(alpha: 0.06),
          child: const Center(child: Icon(Icons.broken_image, size: 28)),
        ),
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
              color: Colors.black38,
              blurRadius: 3,
              offset: Offset(1, 2),
            ),
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
        return Text(
          note.content,
          maxLines: maxContentLines,
          overflow: TextOverflow.ellipsis,
          style: body,
        );
      case NoteType.label:
        return Text(
          note.content,
          maxLines: 2,
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
    this.rotated = true,
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
      _ => _sheet(context, done),
    };
    if (done) paper = Opacity(opacity: 0.72, child: paper);
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
          // Tape is stuck down flat: no pin (so no thread can start from a
          // label either; one can still end on it).
          if (note.type != NoteType.label)
            Positioned(
              top: 0,
              child: _PinTarget(pinned: note.pinned, cb: cb),
            ),
          if (note.locked)
            const Positioned(
              left: 5,
              top: _pinInset + 4,
              child: Icon(Icons.lock, size: 12, color: AppColors.inkSoft),
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
    if (!rotated) return card;
    return NoteTurn(angle: note.pinned ? 0 : noteTilt(note), child: card);
  }

  /// A sheet of sticky paper: adhesive strip, curled corner, the body.
  Widget _sheet(BuildContext context, bool done) {
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
          NotePhoto(path: note.imagePath, maxHeight: 230, radius: 2),
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
              child: NightShade(
                child: DrawingSurface(
                  strokes: note.strokes,
                  canvas: note.canvas,
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
        else if (note.type == NoteType.label)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 13),
            child: Icon(Icons.label, size: 18, color: AppColors.inkSoft),
          )
        else
          _PinTarget(pinned: note.pinned, cb: cb),
        if (note.hasPhoto)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Thumbnail(path: note.imagePath),
          ),
        if (note.type == NoteType.drawing)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _SketchThumb(note: note),
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
        return Text(
          note.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: body,
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
