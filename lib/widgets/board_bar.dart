import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../services/notes_controller.dart';
import '../theme.dart';

/// Emoji offered as board icons.
const boardIcons = [
  '🏠', '💼', '📚', '🎯', '🛒', '✈️', '💡', '🎨',
  '🍳', '💪', '🎵', '🌱', '❤️', '⭐', '📌', '🧠',
];

/// Horizontal strip of board "tabs" with add / rename / icon / delete.
///
/// Tapping a chip switches boards; tapping the *selected* chip opens the
/// manage sheet — the little chevron on it is the hint that it does more.
/// Long-press and drag a chip to reorder boards.
class BoardBar extends StatelessWidget {
  const BoardBar({super.key, required this.notes, required this.textColor});

  final NotesController notes;
  final Color textColor;

  String _displayName(AppLocalizations l10n, Board board) =>
      board.name.isEmpty ? l10n.defaultBoardName : board.name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final boards = notes.boards;

    return SizedBox(
      height: 40,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        buildDefaultDragHandles: false,
        onReorderItem: notes.reorderBoards,
        proxyDecorator: (child, _, animation) => AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) => Transform.scale(
            scale: 1 + 0.08 * Curves.easeInOut.transform(animation.value),
            child: Material(color: Colors.transparent, child: child),
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _AddChip(
            tooltip: l10n.newBoard,
            textColor: textColor,
            onTap: () => _create(context, l10n),
          ),
        ),
        itemCount: boards.length,
        itemBuilder: (context, index) {
          final board = boards[index];
          return Padding(
            key: ValueKey('board-${board.id}'),
            padding: const EdgeInsets.only(right: 8),
            child: ReorderableDelayedDragStartListener(
              index: index,
              child: _BoardChip(
                label: _displayName(l10n, board),
                icon: board.icon,
                selected: board.id == notes.currentBoardId,
                textColor: textColor,
                onTap: () => board.id == notes.currentBoardId
                    ? _manage(context, l10n, board)
                    : notes.selectBoard(board.id),
              ),
            ),
          );
        },
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
                board.icon.isEmpty
                    ? _displayName(l10n, board)
                    : '${board.icon} ${_displayName(l10n, board)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.rename),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: Text(l10n.boardIcon),
              onTap: () => Navigator.pop(context, 'icon'),
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
    } else if (action == 'icon') {
      final icon = await _pickIcon(context, l10n, board.icon);
      if (icon != null) notes.setBoardIcon(board.id, icon);
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

  /// Emoji grid; returns '' for "none", null on cancel.
  Future<String?> _pickIcon(
      BuildContext context, AppLocalizations l10n, String current) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.boardIcon,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _IconChoice(
                    selected: current.isEmpty,
                    onTap: () => Navigator.pop(context, ''),
                    child: Text(l10n.none,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.ink)),
                  ),
                  for (final e in boardIcons)
                    _IconChoice(
                      selected: e == current,
                      onTap: () => Navigator.pop(context, e),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? AppColors.ink.withValues(alpha: 0.12) : null,
          border: Border.all(
            color: selected ? AppColors.ink : Colors.black26,
            width: selected ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
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
    required this.icon,
    required this.selected,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.fromLTRB(
            icon.isEmpty ? 16 : 12, 6, selected ? 10 : 16, 6),
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
            if (icon.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(icon, style: const TextStyle(fontSize: 16)),
              ),
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
