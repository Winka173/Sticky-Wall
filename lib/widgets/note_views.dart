import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
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

double _fontScale(BuildContext context) =>
    Theme.of(context).extension<NoteTextScale>()?.scale ?? 1.0;

/// Callbacks shared by the card and the list tile.
class NoteCallbacks {
  const NoteCallbacks({
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
    required this.onToggleItem,
    required this.onLongPress,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final void Function(int index) onToggleItem;

  /// Opens the note's action sheet (share/save image, pin, delete).
  final VoidCallback onLongPress;
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
          File(path),
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

BoxDecoration paperDecoration(Note note, {bool raised = false}) {
  return BoxDecoration(
    color: noteColor(note.colorIndex, note.guid),
    borderRadius: BorderRadius.circular(3),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: raised ? 0.38 : 0.28),
        blurRadius: raised ? 16 : 7,
        offset: Offset(raised ? 4 : 2, raised ? 10 : 4),
      ),
    ],
  );
}

/// The push-pin at the top of a card; gold and larger when the note is pinned.
class NotePin extends StatelessWidget {
  const NotePin({super.key, required this.pinned});

  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final size = pinned ? 16.0 : 12.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: pinned
              ? const [Color(0xFFFFE082), Color(0xFFF9A825)]
              : const [Color(0xFFEF9A9A), Color(0xFFD32F2F)],
          center: const Alignment(-0.3, -0.3),
        ),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
    );
  }
}

class _ReminderChip extends StatelessWidget {
  const _ReminderChip({required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final overdue = at.isBefore(DateTime.now());
    final ml = MaterialLocalizations.of(context);
    final label = '${ml.formatShortMonthDay(at)} '
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
    final color = overdue ? const Color(0xFFC62828) : const Color(0xFF4E6E4E);

    // The ConstrainedBox guarantees the inner Row always has a bounded width,
    // so the Flexible text can ellipsize instead of overflowing — whatever the
    // parent (a tight card cell or a roomy list row) hands us.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(overdue ? Icons.alarm_on : Icons.alarm,
                size: 13, color: color),
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
      ),
    );
  }
}

TextStyle _inkText(BuildContext context) => TextStyle(
      color: AppColors.ink,
      fontSize: 18 * _fontScale(context),
      height: 1.25,
    );

TextStyle _linkText(BuildContext context) => TextStyle(
      color: const Color(0xFF1A55A5),
      fontSize: 18 * _fontScale(context),
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFF1A55A5),
    );

/// The body of a note (everything but the pin): type-specific content, an
/// emote, a reminder chip and an action row.
class _NoteBody extends StatelessWidget {
  const _NoteBody({
    required this.note,
    required this.cb,
    required this.maxContentLines,
    this.showDelete = true,
  });

  final Note note;
  final NoteCallbacks cb;
  final int maxContentLines;

  /// On the wall the resize handle sits at the bottom-right, so the inline
  /// delete button is hidden there (delete is on the long-press menu).
  final bool showDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (note.imagePath.isNotEmpty) _NotePhoto(path: note.imagePath),
        _content(context),
        const SizedBox(height: 6),
        Row(
          children: [
            if (note.emoji.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(note.emoji, style: const TextStyle(fontSize: 22)),
              ),
            if (note.reminderAt != null)
              Flexible(child: _ReminderChip(at: note.reminderAt!)),
            const Spacer(),
            if (showDelete) ...[
              const SizedBox(width: 4),
              InkResponse(
                onTap: cb.onDelete,
                radius: 18,
                child: const Icon(Icons.delete_outline,
                    size: 19, color: Color(0x99C62828)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _content(BuildContext context) {
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
                    style: _inkText(context)
                        .copyWith(fontWeight: FontWeight.bold)),
              ),
            SizedBox(
              height: 110,
              width: double.infinity,
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
                  style: _inkText(context).copyWith(
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            for (var i = 0; i < note.checklist.length && i < maxContentLines; i++)
              _ChecklistRow(
                item: note.checklist[i],
                onTap: () => cb.onToggleItem(i),
                context: context,
              ),
            if (note.checklist.length > maxContentLines)
              Text('+${note.checklist.length - maxContentLines}…',
                  style: TextStyle(
                      color: AppColors.ink.withValues(alpha: 0.6),
                      fontSize: 14)),
          ],
        );
      case NoteType.normal:
        return Text(
          note.content,
          maxLines: maxContentLines,
          overflow: TextOverflow.ellipsis,
          style: _inkText(context),
        );
    }
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.item,
    required this.onTap,
    required this.context,
  });

  final ChecklistItem item;
  final VoidCallback onTap;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              item.done ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: AppColors.ink.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                item.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.ink,
                  decoration:
                      item.done ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.ink,
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
    this.maxContentLines = 6,
    this.captureKey,
    this.showDelete = true,
  });

  final Note note;
  final NoteCallbacks cb;
  final bool raised;
  final int maxContentLines;

  /// When set, the paper (without the pin) is wrapped in a RepaintBoundary so
  /// it can be rasterized for share/save-as-image.
  final GlobalKey? captureKey;

  /// Hidden on the wall, where the resize handle occupies the bottom-right.
  final bool showDelete;

  @override
  Widget build(BuildContext context) {
    Widget paper = Container(
      decoration: paperDecoration(note, raised: raised),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
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
            padding: const EdgeInsets.fromLTRB(12, 18, 10, 8),
            child: _NoteBody(
              note: note,
              cb: cb,
              maxContentLines: maxContentLines,
              showDelete: showDelete,
            ),
          ),
        ],
      ),
    );
    if (captureKey != null) {
      paper = RepaintBoundary(key: captureKey, child: paper);
    }

    return Transform.rotate(
      angle: note.pinned ? 0 : noteTilt(note),
      child: GestureDetector(
        onTap: cb.onEdit,
        onLongPress: cb.onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            paper,
            Positioned(
              top: -6,
              child: GestureDetector(
                onTap: cb.onTogglePin,
                child: NotePin(pinned: note.pinned),
              ),
            ),
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
    this.captureKey,
  });

  final Note note;
  final NoteCallbacks cb;
  final GlobalKey? captureKey;

  @override
  Widget build(BuildContext context) {
    Widget row = Container(
      decoration: paperDecoration(note),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
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
              GestureDetector(
                onTap: cb.onTogglePin,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: NotePin(pinned: note.pinned),
                ),
              ),
              if (note.imagePath.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(File(note.imagePath),
                        width: 34, height: 34, fit: BoxFit.cover,
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
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _ReminderChip(at: note.reminderAt!),
                ),
              InkResponse(
                onTap: cb.onDelete,
                radius: 18,
                child: const Icon(Icons.delete_outline,
                    size: 20, color: Color(0x99C62828)),
              ),
            ],
    );
  }

  Widget _listContent(BuildContext context) {
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
                style: _inkText(context),
              ),
            ),
          ],
        );
      case NoteType.link:
        return Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${note.content}:', style: _inkText(context)),
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
                note.content.isEmpty ? '($done/${note.checklist.length})'
                    : '${note.content}  ($done/${note.checklist.length})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _inkText(context),
              ),
            ),
          ],
        );
      case NoteType.normal:
        return Text(note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _inkText(context));
    }
  }
}
