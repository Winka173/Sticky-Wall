import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../services/notes_controller.dart';
import '../theme.dart';

/// Horizontal strip of board "tabs" with add / rename / delete.
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final board in notes.boards)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _BoardChip(
                label: _displayName(l10n, board),
                selected: board.id == notes.currentBoardId,
                textColor: textColor,
                onTap: () => notes.selectBoard(board.id),
                onLongPress: () => _manage(context, l10n, board),
              ),
            ),
          _AddChip(textColor: textColor, onTap: () => _create(context, l10n)),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context, AppLocalizations l10n) async {
    final name = await _promptName(context, l10n, title: l10n.newBoard);
    if (name != null && name.trim().isNotEmpty) notes.addBoard(name.trim());
  }

  Future<void> _manage(
      BuildContext context, AppLocalizations l10n, Board board) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.paper,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.rename),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            if (notes.boards.length > 1)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.deleteIcon),
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
      final name = await _promptName(context, l10n,
          title: l10n.rename, initial: _displayName(l10n, board));
      if (name != null && name.trim().isNotEmpty) {
        notes.renameBoard(board.id, name.trim());
      }
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

  Future<String?> _promptName(
    BuildContext context,
    AppLocalizations l10n, {
    required String title,
    String? initial,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.boardName),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l10n.save)),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? textColor.withValues(alpha: 0.18) : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: textColor.withValues(alpha: selected ? 0.9 : 0.35),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.textColor, required this.onTap});

  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}
