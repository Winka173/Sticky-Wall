import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../theme.dart';

Future<void> _openUrl(BuildContext context, String url) async {
  var target = url.trim();
  if (!target.startsWith(RegExp(r'https?://', caseSensitive: false))) {
    target = 'https://$target';
  }
  final uri = Uri.tryParse(target);
  if (uri == null ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpen(url))),
      );
    }
  }
}

/// Deterministic per-note value derived from the guid, stable across runs
/// (String.hashCode is not), used to pick paper color and tilt.
int _noteSeed(Note note) =>
    note.guid.codeUnits.fold(0, (acc, c) => (acc * 31 + c) & 0x7fffffff);

Color notePaperColor(Note note) =>
    AppColors.notePapers[_noteSeed(note) % AppColors.notePapers.length];

/// Small tilt (±~2°) so notes look hand-stuck rather than machine-aligned.
double _noteTilt(Note note, {double step = 0.009}) =>
    ((_noteSeed(note) >> 3) % 5 - 2) * step;

double _fontScale(BuildContext context) =>
    Theme.of(context).extension<NoteTextScale>()?.scale ?? 1.0;

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

class _NoteActions extends StatelessWidget {
  const _NoteActions({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.edit, size: 20, color: Color(0x993B372F)),
          onPressed: onEdit,
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.delete, size: 20, color: AppColors.deleteIcon),
          onPressed: onDelete,
        ),
      ],
    );
  }
}

/// The red push-pin dot at the top of a note.
class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: AppColors.pin,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
    );
  }
}

BoxDecoration _paperDecoration(Note note) {
  return BoxDecoration(
    color: notePaperColor(note),
    borderRadius: BorderRadius.circular(2),
    boxShadow: const [
      BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(2, 4)),
    ],
  );
}

/// List mode: a full-width paper strip with a small tilt.
class NoteListTile extends StatelessWidget {
  const NoteListTile({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Transform.rotate(
        angle: _noteTilt(note, step: 0.004),
        child: Container(
          decoration: _paperDecoration(note),
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          child: Row(
            children: [
              Expanded(
                child: note.type == NoteType.link
                    ? Wrap(
                        spacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('${note.content}:', style: _inkText(context)),
                          InkWell(
                            onTap: () => _openUrl(context, note.url),
                            child: Text(
                              note.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _linkText(context),
                            ),
                          ),
                        ],
                      )
                    : Text(note.content, style: _inkText(context)),
              ),
              _NoteActions(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid mode: a square-ish pastel sticky note pinned to the wall.
class NoteGridCard extends StatelessWidget {
  const NoteGridCard({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _noteTilt(note),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            decoration: _paperDecoration(note),
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: note.type == NoteType.link
                      ? InkWell(
                          onTap: () => _openUrl(context, note.url),
                          child: Text(
                            note.content,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 4,
                            style: _linkText(context),
                          ),
                        )
                      : Text(
                          note.content,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 5,
                          style: _inkText(context),
                        ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: _NoteActions(onEdit: onEdit, onDelete: onDelete),
                ),
              ],
            ),
          ),
          const Positioned(top: -5, child: _Pin()),
        ],
      ),
    );
  }
}
