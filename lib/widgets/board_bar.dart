import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../services/notes_controller.dart';
import '../theme.dart';

/// Horizontal strip of board "tabs" with add / rename / delete.
///
/// Tapping a chip switches boards; tapping the *selected* chip (or
/// long-pressing any) opens rename/delete — the little chevron on the
/// selected chip is the hint that it does more.
class BoardBar extends StatelessWidget {
  const BoardBar({super.key, required this.notes, required this.textColor});

  final NotesController notes;
  final Color textColor;

  String _displayName(AppLocalizations l10n, Board board) =>
      board.name.isEmpty ? l10n.defaultBoardName : board.name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 4),
        children: [
          for (final board in notes.boards)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _BoardChip(
                label: _displayName(l10n, board),
                selected: board.id == notes.currentBoardId,
                textColor: textColor,
                onTap: () => board.id == notes.currentBoardId
                    ? _manage(context, l10n, board)
                    : notes.selectBoard(board.id),
                onLongPress: () => _manage(context, l10n, board),
              ),
            ),
          _AddChip(
            tooltip: l10n.newBoard,
            textColor: textColor,
            onTap: () => _create(context, l10n),
          ),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context, AppLocalizations l10n) async {
    final name = await _promptName(context, l10n, title: l10n.newBoard);
    if (name != null && name.isNotEmpty) notes.addBoard(name);
  }

  Future<void> _manage(
      BuildContext context, AppLocalizations l10n, Board board) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                _displayName(l10n, board),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.rename),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            if (notes.boards.length > 1)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.deleteIcon),
                title: Text(l10n.deleteBoard,
                    style: const TextStyle(color: AppColors.deleteIcon)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    if (action == 'rename') {
      // Pre-fill the stored name, not the localized placeholder: otherwise
      // "Save" on an untouched default board would freeze it in one language.
      final name = await _promptName(context, l10n,
          title: l10n.rename,
          initial: board.name,
          hint: _displayName(l10n, board));
      if (name != null) notes.renameBoard(board.id, name);
    } else if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(l10n.deleteBoardConfirm(_displayName(l10n, board))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.delete)),
          ],
        ),
      );
      if (ok == true) notes.deleteBoard(board.id);
    }
  }

  /// Asks for a board name. Returns the trimmed text, or null on cancel.
  Future<String?> _promptName(
    BuildContext context,
    AppLocalizations l10n, {
    required String title,
    String initial = '',
    String? hint,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(
        title: title,
        label: l10n.boardName,
        initial: initial,
        hint: hint,
        cancelLabel: l10n.cancel,
        saveLabel: l10n.save,
      ),
    );
    return result?.trim();
  }
}

/// Owns its text controller so it is disposed with the dialog (after the
/// close animation), not while the field is still on screen.
class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.label,
    required this.initial,
    required this.cancelLabel,
    required this.saveLabel,
    this.hint,
  });

  final String title;
  final String label;
  final String initial;
  final String? hint;
  final String cancelLabel;
  final String saveLabel;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
        ),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.cancelLabel)),
        FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: Text(widget.saveLabel)),
      ],
    );
  }
}

class _BoardChip extends StatelessWidget {
  const _BoardChip({
    required this.label,
    required this.selected,
    required this.textColor,
    required this.onTap,
    required this.onLongPress,
  });

  final String label;
  final bool selected;
  final Color textColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.fromLTRB(16, 6, selected ? 10 : 16, 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? textColor.withValues(alpha: 0.18) : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: textColor.withValues(alpha: selected ? 0.9 : 0.35),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(Icons.expand_more, size: 18, color: textColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({
    required this.tooltip,
    required this.textColor,
    required this.onTap,
  });

  final String tooltip;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: textColor.withValues(alpha: 0.35)),
          ),
          child: Icon(Icons.add, color: textColor, size: 20),
        ),
      ),
    );
  }
}
