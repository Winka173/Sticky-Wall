import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/board.dart';
import '../theme.dart';

/// Emoji offered as board icons.
const boardIcons = [
  '🏠',
  '💼',
  '📚',
  '🎯',
  '🛒',
  '✈️',
  '💡',
  '🎨',
  '🍳',
  '💪',
  '🎵',
  '🌱',
  '❤️',
  '⭐',
  '📌',
  '🧠',
];

/// Everything the board dialog asks for: how the tab should read.
typedef BoardDraft = ({
  String name,
  String icon,
  bool bold,
  bool italic,
  bool underline,
});

/// Longest name that still reads on a tab; the chip ellipsizes past ~160 px
/// anyway, so more would only be hidden.
const _maxNameLength = 40;

/// Opens the board editor — name, icon and text formatting in one place.
/// Pass [board] to edit an existing one; leave it out for a new board.
/// Returns the trimmed draft, or null when cancelled.
Future<BoardDraft?> showBoardDialog(BuildContext context, {Board? board}) {
  return showDialog<BoardDraft>(
    context: context,
    builder: (context) => _BoardDialog(board: board),
  );
}

/// One paper dialog: the name field shows the formatting live, so what you
/// see is exactly what lands on the tab.
class _BoardDialog extends StatefulWidget {
  const _BoardDialog({this.board});

  final Board? board;

  @override
  State<_BoardDialog> createState() => _BoardDialogState();
}

class _BoardDialogState extends State<_BoardDialog> {
  // Pre-fill the stored name, not the localized placeholder: otherwise
  // "Save" on an untouched default board would freeze it in one language.
  late final _name = TextEditingController(text: widget.board?.name ?? '');
  late String _icon = widget.board?.icon ?? '';
  late final _format = <_Format>{
    if (widget.board?.bold ?? false) _Format.bold,
    if (widget.board?.italic ?? false) _Format.italic,
    if (widget.board?.underline ?? false) _Format.underline,
  };

  bool get _isNew => widget.board == null;

  @override
  void initState() {
    super.initState();
    // Save is only worth pressing once a new board has a name.
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// The formatting as it would be stored, applied to [base].
  TextStyle _styled(TextStyle base) => base.copyWith(
    fontWeight: _format.contains(_Format.bold) ? FontWeight.bold : null,
    fontStyle: _format.contains(_Format.italic) ? FontStyle.italic : null,
    decoration: _format.contains(_Format.underline)
        ? TextDecoration.underline
        : null,
  );

  void _save() {
    Navigator.pop(context, (
      name: _name.text.trim(),
      icon: _icon,
      bold: _format.contains(_Format.bold),
      italic: _format.contains(_Format.italic),
      underline: _format.contains(_Format.underline),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canSave = !_isNew || _name.text.trim().isNotEmpty;
    final sectionStyle = theme.textTheme.labelLarge?.copyWith(
      color: AppColors.inkSoft,
      fontWeight: FontWeight.normal,
    );

    return AlertDialog(
      title: Text(_isNew ? l10n.newBoard : l10n.editBoard),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _IconWell(icon: _icon),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: _maxNameLength,
                    // Live preview: the field is written the way the tab is.
                    style: _styled(
                      theme.textTheme.bodyLarge ??
                          const TextStyle(color: AppColors.ink),
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.boardName,
                      hintText: _isNew ? null : l10n.defaultBoardName,
                      counterText: '',
                    ),
                    onSubmitted: canSave ? (_) => _save() : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.nameStyle, style: sectionStyle),
            const SizedBox(height: 6),
            SegmentedButton<_Format>(
              multiSelectionEnabled: true,
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              selected: _format,
              onSelectionChanged: (s) => setState(() {
                _format
                  ..clear()
                  ..addAll(s);
              }),
              segments: [
                ButtonSegment(
                  value: _Format.bold,
                  icon: const Icon(Icons.format_bold),
                  tooltip: l10n.bold,
                ),
                ButtonSegment(
                  value: _Format.italic,
                  icon: const Icon(Icons.format_italic),
                  tooltip: l10n.italic,
                ),
                ButtonSegment(
                  value: _Format.underline,
                  icon: const Icon(Icons.format_underlined),
                  tooltip: l10n.underline,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.boardIcon, style: sectionStyle),
            const SizedBox(height: 6),
            // One scrolling line, so the dialog stays short above a keyboard.
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _IconChoice(
                    selected: _icon.isEmpty,
                    onTap: () => setState(() => _icon = ''),
                    child: Text(
                      l10n.none,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  for (final e in boardIcons)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _IconChoice(
                        selected: e == _icon,
                        // Tapping the current icon takes it off again.
                        onTap: () =>
                            setState(() => _icon = _icon == e ? '' : e),
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: canSave ? _save : null, child: Text(l10n.save)),
      ],
    );
  }
}

enum _Format { bold, italic, underline }

/// The chosen icon beside the name field; an empty outline until one is
/// picked.
class _IconWell extends StatelessWidget {
  const _IconWell({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.inkHint),
      ),
      child: icon.isEmpty
          ? const Icon(Icons.add_reaction_outlined, color: AppColors.inkSoft)
          : Text(icon, style: const TextStyle(fontSize: 26)),
    );
  }
}

/// One selectable emoji (or "none") in the icon strip.
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
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.control),
          color: selected ? AppColors.ink.withValues(alpha: 0.12) : null,
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.inkHint,
            width: selected ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
