import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../theme.dart';

const _emojiChoices = [
  '😀', '😂', '🥰', '😎', '🤔', '😢', '😡', '😴',
  '🎉', '❤️', '⭐', '🔥', '✅', '📌', '💡', '📞',
  '🛒', '💪', '📚', '⏰', '🍀', '🎁', '☕', '✈️',
];

/// Opens the Create/Edit Note dialog. Returns the edited note (a working copy)
/// on save, or null when cancelled. Duplicate content/links are rejected
/// against [existing] (excluding the note being edited).
Future<Note?> showNoteDialog(
  BuildContext context, {
  required Note note,
  required bool isNew,
  required List<Note> existing,
}) {
  return showDialog<Note>(
    context: context,
    builder: (context) =>
        _NoteDialog(note: note.clone(), isNew: isNew, existing: existing),
  );
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.note,
    required this.isNew,
    required this.existing,
  });

  final Note note;
  final bool isNew;
  final List<Note> existing;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Note _n = widget.note;
  late final TextEditingController _content =
      TextEditingController(text: _n.content);
  late final TextEditingController _url = TextEditingController(text: _n.url);
  final _itemController = TextEditingController();

  @override
  void dispose() {
    _content.dispose();
    _url.dispose();
    _itemController.dispose();
    super.dispose();
  }

  bool _isDuplicate() {
    return widget.existing.any((o) {
      if (o.guid == _n.guid) return false;
      if (_n.type == NoteType.link) {
        return o.url == _url.text.trim() || o.content == _content.text.trim();
      }
      if (_n.type == NoteType.normal) {
        return o.content == _content.text.trim();
      }
      return false;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    _n.content = _content.text.trim();
    _n.url = _n.type == NoteType.link ? _url.text.trim() : '';
    if (_n.type == NoteType.checklist) {
      _n.checklist.removeWhere((i) => i.text.trim().isEmpty);
    } else {
      _n.checklist = [];
    }

    if (_n.type != NoteType.checklist && _isDuplicate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.duplicateExists),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.of(context).pop(_n);
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _n.reminderAt ?? now.add(const Duration(hours: 1)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _n.reminderAt ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null) return;
    setState(() {
      _n.reminderAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      title: Text(widget.isNew ? l10n.createNote : l10n.editNote),
      content: SizedBox(
        width: 340,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector
                SegmentedButton<NoteType>(
                  segments: [
                    ButtonSegment(
                      value: NoteType.normal,
                      label: Text(l10n.typeNormal),
                      icon: const Icon(Icons.notes, size: 18),
                    ),
                    ButtonSegment(
                      value: NoteType.link,
                      label: Text(l10n.typeLink),
                      icon: const Icon(Icons.link, size: 18),
                    ),
                    ButtonSegment(
                      value: NoteType.checklist,
                      label: Text(l10n.typeChecklist),
                      icon: const Icon(Icons.checklist, size: 18),
                    ),
                  ],
                  selected: {_n.type},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _n.type = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _content,
                  decoration: InputDecoration(
                    labelText: _n.type == NoteType.normal
                        ? l10n.content
                        : l10n.title,
                    hintText: l10n.contentHint,
                  ),
                  maxLines: _n.type == NoteType.normal ? 4 : 1,
                  minLines: 1,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.contentRequired
                      : null,
                ),
                if (_n.type == NoteType.link) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _url,
                    decoration: InputDecoration(labelText: l10n.link),
                    keyboardType: TextInputType.url,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.linkRequired
                        : null,
                  ),
                ],
                if (_n.type == NoteType.checklist) _buildChecklistEditor(l10n),
                const SizedBox(height: 16),

                // Emote
                _label(l10n.emote, primary),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final emoji in _emojiChoices)
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => setState(
                          () => _n.emoji = _n.emoji == emoji ? '' : emoji,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: _n.emoji == emoji
                                ? primary.withValues(alpha: 0.25)
                                : null,
                          ),
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Paper color
                _label(l10n.color, primary),
                const SizedBox(height: 6),
                _buildColorRow(l10n),
                const SizedBox(height: 8),

                // Pin
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.pin,
                      style: const TextStyle(color: AppColors.ink)),
                  secondary: const Icon(Icons.push_pin, color: AppColors.pin),
                  value: _n.pinned,
                  onChanged: (v) => setState(() => _n.pinned = v),
                ),

                // Reminder
                _buildReminderRow(l10n),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.isNew ? l10n.add : l10n.update),
        ),
      ],
    );
  }

  Widget _label(String text, Color color) => Text(
        text,
        style: TextStyle(fontSize: 14, color: color),
      );

  Widget _buildChecklistEditor(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        for (var i = 0; i < _n.checklist.length; i++)
          Row(
            children: [
              Checkbox(
                value: _n.checklist[i].done,
                onChanged: (v) =>
                    setState(() => _n.checklist[i].done = v ?? false),
              ),
              Expanded(child: Text(_n.checklist[i].text)),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _n.checklist.removeAt(i)),
              ),
            ],
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _itemController,
                decoration: InputDecoration(hintText: l10n.addItem),
                onSubmitted: (_) => _addItem(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addItem,
            ),
          ],
        ),
      ],
    );
  }

  void _addItem() {
    final text = _itemController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _n.checklist.add(ChecklistItem(text: text));
      _itemController.clear();
    });
  }

  Widget _buildColorRow(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      children: [
        // Auto swatch (derive from guid)
        _colorSwatch(
          color: noteColor(null, _n.guid),
          selected: _n.colorIndex == null,
          label: l10n.colorAuto,
          onTap: () => setState(() => _n.colorIndex = null),
        ),
        for (var i = 0; i < AppColors.notePapers.length; i++)
          _colorSwatch(
            color: AppColors.notePapers[i],
            selected: _n.colorIndex == i,
            onTap: () => setState(() => _n.colorIndex = i),
          ),
      ],
    );
  }

  Widget _colorSwatch({
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    String? label,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.ink : Colors.black26,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: label != null
            ? const Icon(Icons.auto_awesome, size: 15, color: AppColors.ink)
            : (selected
                ? const Icon(Icons.check, size: 18, color: AppColors.ink)
                : null),
      ),
    );
  }

  Widget _buildReminderRow(AppLocalizations l10n) {
    final at = _n.reminderAt;
    final ml = MaterialLocalizations.of(context);
    final label = at == null
        ? l10n.noReminder
        : '${ml.formatMediumDate(at)} '
            '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';

    return Row(
      children: [
        const Icon(Icons.alarm, color: AppColors.ink),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.ink)),
        ),
        if (at != null)
          IconButton(
            tooltip: l10n.clearReminder,
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _n.reminderAt = null),
          ),
        TextButton(
          onPressed: _pickReminder,
          child: Text(l10n.setReminder),
        ),
      ],
    );
  }
}
