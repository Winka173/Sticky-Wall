import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/note.dart';
import '../theme.dart';

Future<void> _openUrl(BuildContext context, String url) async {
  var target = url.trim();
  if (!target.startsWith(RegExp(r'https?://', caseSensitive: false))) {
    target = 'https://$target';
  }
  final uri = Uri.tryParse(target);
  if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }
}

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
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: AppColors.deleteIcon),
          onPressed: onDelete,
        ),
      ],
    );
  }
}

/// Row layout used in list mode: label + link on one line for link notes,
/// pink multi-line text for normal notes, actions at the end.
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          Expanded(
            child: note.type == NoteType.link
                ? Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${note.content}:',
                        style: const TextStyle(color: Colors.white),
                      ),
                      InkWell(
                        onTap: () => _openUrl(context, note.url),
                        child: Text(
                          note.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.link),
                        ),
                      ),
                    ],
                  )
                : Text(
                    note.content,
                    style: const TextStyle(color: AppColors.normalNote),
                  ),
          ),
          _NoteActions(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}

/// Card layout used in grid mode: dark translucent card, link notes show
/// their label as a tappable link.
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(12),
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
                      maxLines: 3,
                      style: const TextStyle(color: AppColors.link),
                    ),
                  )
                : Text(
                    note.content,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                    style: const TextStyle(color: AppColors.normalNote),
                  ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: _NoteActions(onEdit: onEdit, onDelete: onDelete),
          ),
        ],
      ),
    );
  }
}
