import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../services/image_service.dart';
import '../theme.dart';
import 'drawing_canvas.dart';
import 'note_views.dart';

const _emojiChoices = [
  '😀', '😂', '🥰', '😎', '🤔', '😢', '😡', '😴',
  '🎉', '❤️', '⭐', '🔥', '✅', '📌', '💡', '📞',
  '🛒', '💪', '📚', '⏰', '🍀', '🎁', '☕', '✈️',
];

/// Opens the note editor — styled as the sticky note itself, so writing feels
/// like writing on the paper. Returns the edited note (a working copy) on
/// save, or null when cancelled. Duplicate content/links are rejected against
/// [existing] (excluding the note being edited).
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

  static const _ink = AppColors.ink;

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
    if (_n.type != NoteType.drawing) _n.strokes = [];

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

  Future<void> _attachPhoto(ImageSource source) async {
    try {
      final path = await ImageService().pickImage(source);
      if (path != null && mounted) setState(() => _n.imagePath = path);
    } catch (_) {
      // Permission denied, camera error, I/O — leave the note unchanged.
    }
  }

  void _addItem() {
    final text = _itemController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _n.checklist.add(ChecklistItem(text: text));
      _itemController.clear();
    });
  }

  double get _fontScale =>
      Theme.of(context).extension<NoteTextScale>()?.scale ?? 1.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paper = noteColor(_n.colorIndex, _n.guid);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: SingleChildScrollView(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: 400,
              margin: const EdgeInsets.only(top: 9),
              decoration: BoxDecoration(
                color: paper,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 20,
                    offset: Offset(3, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Adhesive strip, like a real sticky note.
                  Container(
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0x24FFFFFF),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _typeRow(l10n),
                          const SizedBox(height: 4),
                          if (_n.imagePath.isNotEmpty) _photoPreview(),
                          _writingArea(l10n),
                          if (_n.type == NoteType.link) _urlField(l10n),
                          if (_n.type == NoteType.checklist)
                            _checklistEditor(l10n),
                          if (_n.type == NoteType.drawing) ...[
                            const SizedBox(height: 6),
                            DrawingEditor(
                              strokes: _n.strokes,
                              onChanged: () => setState(() {}),
                            ),
                          ],
                          if (_n.reminderAt != null) _reminderLine(l10n),
                          const SizedBox(height: 10),
                          _emojiStrip(),
                          const SizedBox(height: 10),
                          _colorRow(),
                          const SizedBox(height: 6),
                          _actionRow(l10n),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The pin doubles as the pin-to-top toggle.
            Positioned(
              top: 0,
              child: Tooltip(
                message: l10n.pin,
                child: GestureDetector(
                  onTap: () => setState(() => _n.pinned = !_n.pinned),
                  child: NotePin(pinned: _n.pinned),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- pieces ---------------------------------------------------------------

  Widget _typeRow(AppLocalizations l10n) {
    final types = [
      (NoteType.normal, Icons.notes, l10n.typeNormal),
      (NoteType.link, Icons.link, l10n.typeLink),
      (NoteType.checklist, Icons.checklist, l10n.typeChecklist),
      (NoteType.drawing, Icons.brush, l10n.typeDrawing),
    ];
    return Row(
      children: [
        for (final (t, icon, label) in types)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Tooltip(
              message: label,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _n.type = t),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _n.type == t
                        ? _ink.withValues(alpha: 0.16)
                        : Colors.transparent,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: _n.type == t
                        ? _ink
                        : _ink.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
        const Spacer(),
        IconButton(
          tooltip: l10n.photo,
          onPressed: () => _photoMenu(l10n),
          icon: Icon(
            _n.imagePath.isEmpty ? Icons.photo_camera_back : Icons.photo,
            size: 21,
            color:
                _n.imagePath.isEmpty ? _ink.withValues(alpha: 0.45) : _ink,
          ),
        ),
        IconButton(
          tooltip: l10n.reminder,
          onPressed: _pickReminder,
          icon: Icon(
            _n.reminderAt == null ? Icons.alarm_add : Icons.alarm_on,
            size: 21,
            color:
                _n.reminderAt == null ? _ink.withValues(alpha: 0.45) : _ink,
          ),
        ),
      ],
    );
  }

  Future<void> _photoMenu(AppLocalizations l10n) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.paper,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.fromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _attachPhoto(source);
  }

  Widget _photoPreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(_n.imagePath),
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 130,
                child: Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ),
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.black54,
              radius: 13,
              child: Icon(Icons.close, size: 15, color: Colors.white),
            ),
            onPressed: () => setState(() => _n.imagePath = ''),
          ),
        ],
      ),
    );
  }

  /// The writing surface: borderless handwriting text over faint ruled lines
  /// (for normal notes), so typing reads as writing on the paper.
  Widget _writingArea(AppLocalizations l10n) {
    final scale = _fontScale;
    final isNormal = _n.type == NoteType.normal;
    final fontSize = (isNormal ? 20.0 : 19.0) * scale;
    final lineHeight = fontSize * 1.5;

    final field = TextFormField(
      controller: _content,
      cursorColor: _ink,
      style: TextStyle(fontSize: fontSize, height: 1.5, color: _ink),
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        hintText: isNormal ? l10n.contentHint : l10n.title,
        hintStyle: TextStyle(
          fontSize: fontSize,
          height: 1.5,
          color: _ink.withValues(alpha: 0.35),
        ),
      ),
      maxLines: isNormal ? 6 : 1,
      minLines: isNormal ? 4 : 1,
      validator: (v) {
        final needs =
            _n.type == NoteType.normal || _n.type == NoteType.link;
        return (needs && (v == null || v.trim().isEmpty))
            ? l10n.contentRequired
            : null;
      },
    );

    if (!isNormal) return field;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _RulesPainter(
              lineHeight: lineHeight,
              color: _ink.withValues(alpha: 0.10),
            ),
          ),
        ),
        field,
      ],
    );
  }

  Widget _urlField(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, right: 6),
          child:
              Icon(Icons.link, size: 18, color: _ink.withValues(alpha: 0.6)),
        ),
        Expanded(
          child: TextFormField(
            controller: _url,
            cursorColor: _ink,
            keyboardType: TextInputType.url,
            style: const TextStyle(
                fontSize: 16, color: Color(0xFF1A55A5)),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: l10n.link,
              hintStyle: TextStyle(
                  fontSize: 16, color: _ink.withValues(alpha: 0.35)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? l10n.linkRequired
                : null,
          ),
        ),
      ],
    );
  }

  Widget _checklistEditor(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _n.checklist.length; i++)
          Row(
            children: [
              Checkbox(
                value: _n.checklist[i].done,
                activeColor: _ink,
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: _ink.withValues(alpha: 0.6)),
                onChanged: (v) =>
                    setState(() => _n.checklist[i].done = v ?? false),
              ),
              Expanded(
                child: Text(
                  _n.checklist[i].text,
                  style: TextStyle(
                    fontSize: 17,
                    color: _ink,
                    decoration: _n.checklist[i].done
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              InkResponse(
                radius: 16,
                onTap: () => setState(() => _n.checklist.removeAt(i)),
                child: Icon(Icons.close,
                    size: 17, color: _ink.withValues(alpha: 0.5)),
              ),
            ],
          ),
        Row(
          children: [
            Icon(Icons.add, size: 18, color: _ink.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _itemController,
                cursorColor: _ink,
                style: const TextStyle(fontSize: 16, color: _ink),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: l10n.addItem,
                  hintStyle: TextStyle(
                      fontSize: 16, color: _ink.withValues(alpha: 0.35)),
                ),
                onSubmitted: (_) => _addItem(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reminderLine(AppLocalizations l10n) {
    final ml = MaterialLocalizations.of(context);
    final at = _n.reminderAt!;
    final label =
        '${ml.formatMediumDate(at)} ${ml.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.alarm, size: 16, color: _ink.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 14, color: _ink.withValues(alpha: 0.7))),
          const SizedBox(width: 4),
          InkResponse(
            radius: 14,
            onTap: () => setState(() => _n.reminderAt = null),
            child: Icon(Icons.close,
                size: 15, color: _ink.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _emojiStrip() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final emoji in _emojiChoices)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () =>
                  setState(() => _n.emoji = _n.emoji == emoji ? '' : emoji),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _n.emoji == emoji
                      ? _ink.withValues(alpha: 0.16)
                      : null,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 21)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _colorRow() {
    return Row(
      children: [
        _swatch(
          color: noteColor(null, _n.guid),
          selected: _n.colorIndex == null,
          auto: true,
          onTap: () => setState(() => _n.colorIndex = null),
        ),
        for (var i = 0; i < AppColors.notePapers.length; i++)
          _swatch(
            color: AppColors.notePapers[i],
            selected: _n.colorIndex == i,
            onTap: () => setState(() => _n.colorIndex = i),
          ),
      ],
    );
  }

  Widget _swatch({
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    bool auto = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: selected ? 30 : 26,
          height: selected ? 30 : 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? _ink : Colors.black26,
              width: selected ? 2 : 1,
            ),
          ),
          child: auto
              ? Icon(Icons.auto_awesome,
                  size: 13, color: _ink.withValues(alpha: 0.7))
              : null,
        ),
      ),
    );
  }

  Widget _actionRow(AppLocalizations l10n) {
    return Row(
      children: [
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
              foregroundColor: _ink.withValues(alpha: 0.7)),
          child: Text(l10n.cancel),
        ),
        const SizedBox(width: 4),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: _ink,
            foregroundColor: AppColors.chalk,
          ),
          child: Text(widget.isNew ? l10n.add : l10n.update),
        ),
      ],
    );
  }
}

/// Faint horizontal ruled lines, spaced to the text's line height so the
/// writing sits on them like real note paper.
class _RulesPainter extends CustomPainter {
  _RulesPainter({required this.lineHeight, required this.color});

  final double lineHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = lineHeight - 3; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RulesPainter oldDelegate) =>
      oldDelegate.lineHeight != lineHeight || oldDelegate.color != color;
}
