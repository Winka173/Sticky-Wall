import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// save, or null when cancelled. A link already pinned on the wall (in
/// [existing], excluding the note being edited) is rejected.
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

/// Controller + focus for one editable checklist row.
class _ItemField {
  _ItemField(String text) : controller = TextEditingController(text: text);

  final TextEditingController controller;
  final focus = FocusNode();

  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

class _NoteDialogState extends State<_NoteDialog>
    with SingleTickerProviderStateMixin {
  late final Note _n = widget.note;
  late final _content = TextEditingController(text: _n.content);
  late final _url = TextEditingController(text: _n.url);
  final _urlFocus = FocusNode();
  final _newItem = TextEditingController();
  final _newItemFocus = FocusNode();
  late final List<_ItemField> _items = [
    for (final item in _n.checklist) _ItemField(item.text),
  ];

  // Photos copied into the app during this editing session. They are only
  // kept if the note is saved *with* one of them attached; otherwise they'd
  // pile up unreferenced in the documents directory.
  final _addedPhotos = <String>{};
  bool _saved = false;

  String? _error;
  bool _showEmoji = false;
  bool _showColors = false;

  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  static const _ink = AppColors.ink;
  static const _paperWidth = 360.0;

  @override
  void initState() {
    super.initState();
    _content.addListener(_clearError);
    _url.addListener(_clearError);
  }

  @override
  void dispose() {
    for (final path in _addedPhotos) {
      if (!_saved || path != _n.imagePath) ImageService.deleteFile(path);
    }
    _content.dispose();
    _url.dispose();
    _urlFocus.dispose();
    _newItem.dispose();
    _newItemFocus.dispose();
    for (final f in _items) {
      f.dispose();
    }
    _shake.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _fail(String message) {
    HapticFeedback.heavyImpact();
    setState(() => _error = message);
    _shake.forward(from: 0);
  }

  // --- saving ----------------------------------------------------------------

  /// Two links are the same page if they differ only by scheme, "www." or a
  /// trailing slash.
  static String _urlKey(String url) => url
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^https?://'), '')
      .replaceFirst(RegExp(r'^www\.'), '')
      .replaceFirst(RegExp(r'/+$'), '');

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final content = _content.text.trim();
    final url = _url.text.trim();

    // Whatever is typed in the "add item" field counts as an item too — it
    // is what the user meant, even if they never pressed enter.
    _addItem(keepFocus: false);
    for (var i = 0; i < _items.length; i++) {
      _n.checklist[i].text = _items[i].controller.text.trim();
    }

    String? error;
    switch (_n.type) {
      case NoteType.normal:
        if (content.isEmpty) error = l10n.contentRequired;
      case NoteType.link:
        if (url.isEmpty) {
          error = l10n.linkRequired;
        } else if (widget.existing.any((o) =>
            o.guid != _n.guid &&
            o.type == NoteType.link &&
            _urlKey(o.url) == _urlKey(url))) {
          error = l10n.duplicateExists;
        }
      case NoteType.checklist:
        if (content.isEmpty &&
            _n.checklist.every((i) => i.text.isEmpty)) {
          error = l10n.noteEmpty;
        }
      case NoteType.drawing:
        if (content.isEmpty && _n.strokes.isEmpty) error = l10n.noteEmpty;
    }
    if (error != null) {
      _fail(error);
      return;
    }

    // An untitled link shows its address on the card.
    _n.content =
        content.isEmpty && _n.type == NoteType.link ? url : content;
    _n.url = _n.type == NoteType.link ? url : '';
    if (_n.type == NoteType.checklist) {
      _n.checklist.removeWhere((i) => i.text.isEmpty);
    } else {
      _n.checklist = [];
    }
    if (_n.type != NoteType.drawing) _n.strokes = [];

    _saved = true;
    Navigator.of(context).pop(_n);
  }

  // --- reminder / photo / checklist ---------------------------------------------

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // An overdue reminder would put initialDate before firstDate, which the
    // picker rejects outright — start from now instead.
    var initial = _n.reminderAt ?? now.add(const Duration(hours: 1));
    if (initial.isBefore(today)) initial = now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _n.reminderAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _attachPhoto(ImageSource source) async {
    try {
      final path = await ImageService().pickImage(source);
      if (path == null || !mounted) return;
      _discardPhotoIfAdded(_n.imagePath);
      _addedPhotos.add(path);
      setState(() => _n.imagePath = path);
    } catch (_) {
      // Permission denied, camera error, I/O — leave the note unchanged.
    }
  }

  void _removePhoto() {
    _discardPhotoIfAdded(_n.imagePath);
    setState(() => _n.imagePath = '');
  }

  /// A photo attached earlier in this session and now replaced/removed can be
  /// deleted right away; the note's original photo is the caller's business.
  void _discardPhotoIfAdded(String path) {
    if (_addedPhotos.remove(path)) ImageService.deleteFile(path);
  }

  void _addItem({bool keepFocus = true}) {
    final text = _newItem.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _n.checklist.add(ChecklistItem(text: text));
      _items.add(_ItemField(text));
      _newItem.clear();
      _error = null;
    });
    if (keepFocus) _newItemFocus.requestFocus();
  }

  void _removeItem(int i) {
    final field = _items[i];
    setState(() {
      _n.checklist.removeAt(i);
      _items.removeAt(i);
    });
    // Its TextField is still in the tree until this frame's rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) => field.dispose());
  }

  void _setType(NoteType t) {
    if (_n.type == t) return;
    setState(() {
      _n.type = t;
      _error = null;
    });
  }

  // --- build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paper = paperColorOf(context, _n.colorIndex, _n.guid);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                final t = _shake.value;
                final dx = math.sin(t * math.pi * 4) * 6 * (1 - t);
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _paperWidth,
                margin: const EdgeInsets.only(top: 9),
                decoration: BoxDecoration(
                  color: paper,
                  borderRadius: BorderRadius.circular(AppRadii.paper),
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
                    _topStrip(l10n),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_n.imagePath.isNotEmpty) _photoPreview(l10n),
                          _writingArea(l10n),
                          if (_n.type == NoteType.link) _urlField(l10n),
                          if (_n.type == NoteType.checklist)
                            _checklistEditor(l10n),
                          if (_n.type == NoteType.drawing) ...[
                            const SizedBox(height: 8),
                            DrawingEditor(
                              strokes: _n.strokes,
                              onChanged: () => setState(() => _error = null),
                            ),
                          ],
                          _errorLine(),
                          if (_n.reminderAt != null) _reminderLine(l10n),
                          const SizedBox(height: 10),
                          _toolRow(l10n),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            alignment: Alignment.topCenter,
                            child: _showEmoji
                                ? _emojiStrip()
                                : _showColors
                                    ? _colorRow()
                                    : const SizedBox(width: double.infinity),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // The pin doubles as the pin-to-top toggle.
            Positioned(
              top: 0,
              child: Tooltip(
                message: _n.pinned ? l10n.unpin : l10n.pin,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _n.pinned = !_n.pinned);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: NotePin(pinned: _n.pinned),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- pieces ---------------------------------------------------------------

  /// The adhesive strip along the top carries Cancel and Save, so saving is
  /// always one tap away and never hidden under the keyboard.
  Widget _topStrip(AppLocalizations l10n) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Color(0x2EFFFFFF),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.paper)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.cancel,
            color: _ink.withValues(alpha: 0.7),
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Tooltip(
              message: widget.isNew ? l10n.add : l10n.save,
              child: Material(
                color: _ink,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _save,
                  child: const SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(Icons.check, size: 20, color: AppColors.chalk),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPreview(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(ImageService.resolve(_n.imagePath)),
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
            tooltip: l10n.delete,
            icon: const CircleAvatar(
              backgroundColor: Colors.black54,
              radius: 13,
              child: Icon(Icons.close, size: 15, color: Colors.white),
            ),
            onPressed: _removePhoto,
          ),
        ],
      ),
    );
  }

  /// The writing surface: the same handwriting style the card uses, over
  /// faint ruled lines that sit exactly under each baseline — so typing here
  /// reads as writing on the paper, and what you see is what gets stuck up.
  Widget _writingArea(AppLocalizations l10n) {
    final isNormal = _n.type == NoteType.normal;
    final style = noteBodyStyle(context);
    final lineHeight = style.fontSize! * style.height!;
    final strut = StrutStyle(
      fontSize: style.fontSize,
      height: style.height,
      forceStrutHeight: true,
    );

    final field = TextField(
      controller: _content,
      autofocus: widget.isNew,
      cursorColor: _ink,
      style: style,
      strutStyle: strut,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: isNormal ? TextInputType.multiline : TextInputType.text,
      textInputAction: isNormal
          ? TextInputAction.newline
          : _n.type == NoteType.drawing
              ? TextInputAction.done
              : TextInputAction.next,
      onSubmitted: isNormal
          ? null
          : (_) => switch (_n.type) {
                NoteType.link => _urlFocus.requestFocus(),
                NoteType.checklist => (_items.isEmpty
                        ? _newItemFocus
                        : _items.first.focus)
                    .requestFocus(),
                _ => null,
              },
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        hintText: isNormal ? l10n.contentHint : l10n.title,
        hintStyle: style.copyWith(color: _ink.withValues(alpha: 0.35)),
      ),
      maxLines: isNormal ? null : 1,
      minLines: isNormal ? 5 : 1,
    );

    if (!isNormal) return field;

    // Where the first baseline falls inside a strut-sized line box.
    final probe = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      strutStyle: strut,
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline =
        probe.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    probe.dispose();

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _RulesPainter(
              firstLine: baseline + 2,
              lineHeight: lineHeight,
              color: _ink.withValues(alpha: 0.12),
            ),
          ),
        ),
        field,
      ],
    );
  }

  Widget _errorLine() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      alignment: Alignment.topLeft,
      child: _error == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: AppColors.deleteIcon),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.deleteIcon),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _urlField(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child:
                Icon(Icons.link, size: 18, color: _ink.withValues(alpha: 0.6)),
          ),
          Expanded(
            child: TextField(
              controller: _url,
              focusNode: _urlFocus,
              cursorColor: _ink,
              keyboardType: TextInputType.url,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              style: const TextStyle(fontSize: 16, color: AppColors.link),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: l10n.link,
                hintStyle: TextStyle(
                    fontSize: 16, color: _ink.withValues(alpha: 0.35)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistEditor(AppLocalizations l10n) {
    final itemStyle = TextStyle(fontSize: 17 * noteFontScale(context), color: _ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _items.length; i++)
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
                // Items are editable in place rather than delete-and-retype.
                child: TextField(
                  controller: _items[i].controller,
                  focusNode: _items[i].focus,
                  cursorColor: _ink,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) {
                    _n.checklist[i].text = v;
                    _clearError();
                  },
                  onSubmitted: (_) => (i + 1 < _items.length
                          ? _items[i + 1].focus
                          : _newItemFocus)
                      .requestFocus(),
                  style: itemStyle.copyWith(
                    decoration: _n.checklist[i].done
                        ? TextDecoration.lineThrough
                        : null,
                    color: _n.checklist[i].done
                        ? _ink.withValues(alpha: 0.5)
                        : _ink,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.delete,
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                color: _ink.withValues(alpha: 0.5),
                icon: const Icon(Icons.close),
                onPressed: () => _removeItem(i),
              ),
            ],
          ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.add, size: 20, color: _ink.withValues(alpha: 0.5)),
            ),
            Expanded(
              child: TextField(
                controller: _newItem,
                focusNode: _newItemFocus,
                cursorColor: _ink,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                // Adds the item and keeps the keyboard up for the next one
                // (a bare onSubmitted would let the field lose focus).
                onEditingComplete: _addItem,
                style: itemStyle,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: l10n.addItem,
                  hintStyle:
                      itemStyle.copyWith(color: _ink.withValues(alpha: 0.35)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String repeatLabel(AppLocalizations l10n, ReminderRepeat r) =>
      switch (r) {
        ReminderRepeat.none => l10n.repeatNone,
        ReminderRepeat.daily => l10n.repeatDaily,
        ReminderRepeat.weekly => l10n.repeatWeekly,
        ReminderRepeat.monthly => l10n.repeatMonthly,
      };

  Widget _reminderLine(AppLocalizations l10n) {
    final ml = MaterialLocalizations.of(context);
    final repeats = _n.repeat != ReminderRepeat.none;
    // For a repeating reminder show when it rings *next*, not when it began.
    final at = _n.nextReminder()!;
    final overdue = !repeats && at.isBefore(DateTime.now());
    final color = overdue ? AppColors.deleteIcon : _ink.withValues(alpha: 0.7);
    final label =
        '${ml.formatMediumDate(at)} ${ml.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(repeats ? Icons.repeat : Icons.alarm, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: _pickReminder,
              child: Text(label, style: TextStyle(fontSize: 14, color: color)),
            ),
          ),
          // "Once / Daily / Weekly / Monthly" — a small pill that opens a menu.
          PopupMenuButton<ReminderRepeat>(
            tooltip: l10n.repeat,
            initialValue: _n.repeat,
            onSelected: (r) => setState(() => _n.repeat = r),
            itemBuilder: (_) => [
              for (final r in ReminderRepeat.values)
                PopupMenuItem(value: r, child: Text(repeatLabel(l10n, r))),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _ink.withValues(alpha: repeats ? 0.14 : 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                repeatLabel(l10n, _n.repeat),
                style: TextStyle(fontSize: 13, color: _ink.withValues(alpha: 0.8)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkResponse(
            radius: 14,
            onTap: () => setState(() {
              _n.reminderAt = null;
              _n.repeat = ReminderRepeat.none;
            }),
            child: Icon(Icons.close,
                size: 16, color: _ink.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  /// One compact row: note type, then photo / reminder / emote / paper color.
  /// Scrolls sideways on very narrow screens instead of overflowing.
  Widget _toolRow(AppLocalizations l10n) {
    final types = [
      (NoteType.normal, Icons.notes, l10n.typeNormal),
      (NoteType.link, Icons.link, l10n.typeLink),
      (NoteType.checklist, Icons.checklist, l10n.typeChecklist),
      (NoteType.drawing, Icons.brush_outlined, l10n.typeDrawing),
    ];
    final faint = _ink.withValues(alpha: 0.45);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _ink.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                for (final (t, icon, label) in types)
                  Tooltip(
                    message: label,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _setType(t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 34,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: _n.type == t ? _ink : Colors.transparent,
                        ),
                        child: Icon(icon,
                            size: 19,
                            color: _n.type == t ? AppColors.chalk : faint),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: l10n.photo,
            onPressed: () => _photoMenu(l10n),
            color: _n.imagePath.isEmpty ? faint : _ink,
            icon: Icon(
              _n.imagePath.isEmpty
                  ? Icons.photo_camera_back_outlined
                  : Icons.photo,
              size: 22,
            ),
          ),
          IconButton(
            tooltip: l10n.reminder,
            onPressed: _pickReminder,
            color: _n.reminderAt == null ? faint : _ink,
            icon: Icon(
              _n.reminderAt == null ? Icons.alarm_add : Icons.alarm_on,
              size: 22,
            ),
          ),
          IconButton(
            tooltip: l10n.emote,
            onPressed: () => setState(() {
              _showEmoji = !_showEmoji;
              _showColors = false;
            }),
            color: _showEmoji || _n.emoji.isNotEmpty ? _ink : faint,
            icon: _n.emoji.isEmpty
                ? const Icon(Icons.add_reaction_outlined, size: 22)
                : Text(_n.emoji, style: const TextStyle(fontSize: 20)),
          ),
          IconButton(
            tooltip: l10n.color,
            onPressed: () => setState(() {
              _showColors = !_showColors;
              _showEmoji = false;
            }),
            icon: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: paperColorOf(context, _n.colorIndex, _n.guid),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _showColors ? _ink : _ink.withValues(alpha: 0.5),
                  width: _showColors ? 2 : 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _photoMenu(AppLocalizations l10n) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.fromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null && mounted) await _attachPhoto(source);
  }

  Widget _emojiStrip() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final emoji in _emojiChoices)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() {
                  _n.emoji = _n.emoji == emoji ? '' : emoji;
                  _showEmoji = false;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _n.emoji == emoji
                        ? _ink.withValues(alpha: 0.16)
                        : null,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _colorRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _swatch(
            color: noteColor(null, _n.guid),
            selected: _n.colorIndex == null,
            auto: true,
            onTap: () => _pickColor(null),
          ),
          for (var i = 0; i < AppColors.notePapers.length; i++)
            _swatch(
              color: AppColors.notePapers[i],
              selected: _n.colorIndex == i,
              onTap: () => _pickColor(i),
            ),
        ],
      ),
    );
  }

  void _pickColor(int? index) {
    HapticFeedback.selectionClick();
    setState(() {
      _n.colorIndex = index;
      _showColors = false;
    });
  }

  Widget _swatch({
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    bool auto = false,
  }) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: selected ? 32 : 26,
            height: selected ? 32 : 26,
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
      ),
    );
  }
}

/// Faint horizontal ruled lines, one just under each text baseline, so the
/// writing sits on them like real note paper.
class _RulesPainter extends CustomPainter {
  _RulesPainter({
    required this.firstLine,
    required this.lineHeight,
    required this.color,
  });

  final double firstLine;
  final double lineHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (lineHeight <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = firstLine; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RulesPainter oldDelegate) =>
      oldDelegate.firstLine != firstLine ||
      oldDelegate.lineHeight != lineHeight ||
      oldDelegate.color != color;
}
