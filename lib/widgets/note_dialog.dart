import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';
import '../services/audio_service.dart';
import '../services/image_service.dart';
import '../services/pro_controller.dart';
import '../services/reminder_service.dart';
import '../theme.dart';
import 'action_sheet.dart';
import 'audio_note.dart';
import 'drawing_canvas.dart';
import 'keyboard_tappable.dart';
import 'note_views.dart';
import 'paper_color_dialog.dart';
import 'photo_viewer.dart';
import 'pro_sheet.dart';

part 'note_dialog_pieces.dart';

const _emojiChoices = [
  '😀',
  '😂',
  '🥰',
  '😎',
  '🤔',
  '😢',
  '😡',
  '😴',
  '🎉',
  '❤️',
  '⭐',
  '🔥',
  '✅',
  '📌',
  '💡',
  '📞',
  '🛒',
  '💪',
  '📚',
  '⏰',
  '🍀',
  '🎁',
  '☕',
  '✈️',
];

/// Opens the note editor — styled as the sticky note itself, so writing feels
/// like writing on the paper. Returns the edited note (a working copy) on
/// save, or null when cancelled. A link already pinned on the wall (in
/// [existing], excluding the note being edited) is rejected. With
/// [onDelete] the paper has a bin: the editor closes and calls it.
Future<Note?> showNoteDialog(
  BuildContext context, {
  required Note note,
  required bool isNew,
  required List<Note> existing,
  VoidCallback? onDelete,
  bool readable = false,
  ValueChanged<bool>? onReadable,
}) {
  return showDialog<Note>(
    context: context,
    builder: (context) => _NoteDialog(
      note: note.clone(),
      isNew: isNew,
      existing: existing,
      onDelete: onDelete,
      readable: readable,
      onReadable: onReadable,
    ),
  );
}

/// The note editor: a sheet of paper with type-specific fields (text, link,
/// checklist, drawing or photo print), plus photos, emote, colour and
/// reminder controls.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.note,
    required this.isNew,
    required this.existing,
    this.onDelete,
    this.readable = false,
    this.onReadable,
  });

  final Note note;
  final bool isNew;
  final List<Note> existing;
  final VoidCallback? onDelete;

  /// Write in a plain readable face instead of the handwriting; the switch
  /// on the paper flips it and [onReadable] remembers the choice.
  final bool readable;
  final ValueChanged<bool>? onReadable;

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

  // Photos copied into the app during this editing session (the user may
  // swap the picture several times). Only the one the note is saved with is
  // kept; the rest would pile up unreferenced in the documents directory.
  final _addedPhotos = <String>{};
  // Recordings made in this session, kept on the same terms as photos.
  final _addedAudio = <String>{};
  final _voice = GlobalKey<VoiceRecorderPanelState>();
  bool _saved = false;

  /// The note as it was opened, to tell whether closing would lose anything.
  late final String _initial;

  String? _error;

  /// Set when the system refused notifications, so a reminder would be set
  /// but never ring.
  bool _notificationsOff = false;
  bool _showEmoji = false;
  bool _showColors = false;
  late bool _readable = widget.readable;

  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  static const _ink = AppColors.ink;
  static const _paperWidth = 360.0;

  @override
  void initState() {
    super.initState();
    _initial = jsonEncode(widget.note.toJson());
    _content.addListener(_clearError);
    _url.addListener(_clearError);
  }

  @override
  void dispose() {
    for (final path in _addedPhotos) {
      if (!_saved || _n.imagePath != path) ImageService.deleteFile(path);
    }
    for (final path in _addedAudio) {
      if (!_saved || _n.audioPath != path) AudioService.deleteFile(path);
    }
    // A voice note still playing from the editor stops with it.
    final playing = AudioPlayback.instance.current;
    if (playing != null &&
        (playing == _n.audioPath || _addedAudio.contains(playing))) {
      AudioPlayback.instance.stop();
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
    // The words and the buzz carry it; the shake is extra motion.
    if (!MediaQuery.disableAnimationsOf(context)) _shake.forward(from: 0);
  }

  /// [setState] for the editor's pieces (see note_dialog_pieces.dart),
  /// which build parts of this State from an extension.
  void _update(VoidCallback change) => setState(change);

  static String repeatLabel(AppLocalizations l10n, ReminderRepeat r) =>
      switch (r) {
        ReminderRepeat.none => l10n.repeatNone,
        ReminderRepeat.daily => l10n.repeatDaily,
        ReminderRepeat.weekly => l10n.repeatWeekly,
        ReminderRepeat.monthly => l10n.repeatMonthly,
      };

  // --- saving ----------------------------------------------------------------

  /// Whether anything typed, drawn or picked would be lost by closing now.
  /// Text fields are read from their controllers: the note only takes them
  /// on save.
  bool get _dirty {
    if (_newItem.text.trim().isNotEmpty) return true;
    final now = _n.toJson()
      ..['content'] = _content.text
      ..['url'] = _url.text
      ..['checklist'] = [
        for (var i = 0; i < _n.checklist.length; i++)
          {
            'text': i < _items.length
                ? _items[i].controller.text
                : _n.checklist[i].text,
            'done': _n.checklist[i].done,
          },
      ];
    return jsonEncode(now) != _initial;
  }

  /// Back and a tap beside the paper keep what was written, as putting a
  /// note down would; only the ✕ throws an edit away.
  Future<void> _leave() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    await _save(leaving: true);
  }

  /// The ✕, and leaving a note that cannot be saved as it is: an untouched
  /// note just closes, an edited one asks first.
  Future<void> _close() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.discardChangesTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepEditing),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteIcon),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  /// Two links are the same page if they differ only by scheme, "www." or a
  /// trailing slash.
  static String _urlKey(String url) => url
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^https?://'), '')
      .replaceFirst(RegExp(r'^www\.'), '')
      .replaceFirst(RegExp(r'/+$'), '');

  Future<void> _save({bool leaving = false}) async {
    final l10n = AppLocalizations.of(context)!;
    // A take still running is what the user meant to keep: end it first.
    final voice = _voice.currentState;
    if (voice != null && voice.isRecording) {
      await voice.finish();
      if (!mounted) return;
    }
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
        } else if (widget.existing.any(
          (o) =>
              o.guid != _n.guid &&
              o.type == NoteType.link &&
              _urlKey(o.url) == _urlKey(url),
        )) {
          error = l10n.duplicateExists;
        }
      case NoteType.checklist:
        if (content.isEmpty && _n.checklist.every((i) => i.text.isEmpty)) {
          error = l10n.noteEmpty;
        }
      case NoteType.drawing:
        if (content.isEmpty && _n.strokes.isEmpty) error = l10n.noteEmpty;
      case NoteType.photo:
        if (!_n.hasPhoto) error = l10n.photoRequired;
      case NoteType.label:
        if (content.isEmpty) error = l10n.contentRequired;
      case NoteType.audio:
        if (!_n.hasAudio) error = l10n.recordingRequired;
      case NoteType.sticker:
        // Stickers never open the editor; nothing to check.
        break;
    }
    if (error != null) {
      // Leaving with nothing that can be kept: ask, rather than shake a note
      // the user is putting down.
      if (leaving) {
        await _close();
      } else {
        _fail(error);
      }
      return;
    }

    // A list saved as text keeps its items as bullet lines rather than
    // losing them; a sketch or an address has no text form, so ask first.
    final items = [
      for (final i in _n.checklist)
        if (i.text.isNotEmpty) i.text,
    ];
    final dropsDrawing = _n.type != NoteType.drawing && _n.strokes.isNotEmpty;
    final dropsLink = _n.type != NoteType.link && url.isNotEmpty;
    final dropsVoice = _n.type != NoteType.audio && _n.hasAudio;
    if (dropsDrawing || dropsLink || dropsVoice) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(l10n.typeChangeDrops(_typeName(l10n, _n.type))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.keepEditing),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.saveAnyway),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    var text = content;
    if (_n.type != NoteType.checklist && items.isNotEmpty) {
      final bullets = items.map((t) => '- $t').join('\n');
      text = text.isEmpty ? bullets : '$text\n$bullets';
    }

    // An untitled link shows its address on the card.
    _n.content = text.isEmpty && _n.type == NoteType.link ? url : text;
    _n.url = _n.type == NoteType.link ? url : '';
    if (_n.type == NoteType.checklist) {
      _n.checklist.removeWhere((i) => i.text.isEmpty);
    } else {
      _n.checklist = [];
    }
    if (_n.type != NoteType.drawing) _n.strokes = [];
    if (_n.type != NoteType.audio) {
      _n
        ..audioPath = ''
        ..audioMs = 0;
    }

    _saved = true;
    Navigator.of(context).pop(_n);
  }

  static String _typeName(AppLocalizations l10n, NoteType t) => switch (t) {
    NoteType.normal => l10n.typeNormal,
    NoteType.link => l10n.typeLink,
    NoteType.checklist => l10n.typeChecklist,
    NoteType.drawing => l10n.typeDrawing,
    NoteType.photo => l10n.typePhoto,
    NoteType.label => l10n.typeLabel,
    NoteType.audio => l10n.typeAudio,
    NoteType.sticker => l10n.typeSticker,
  };

  // --- reminder / photo / checklist ---------------------------------------------

  /// The usual times are one tap; any other is a date and a time away.
  Future<void> _pickReminder() async {
    final l10n = AppLocalizations.of(context)!;
    final ml = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final inHour = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(hours: 1));
    final tonight = DateTime(now.year, now.month, now.day, 18);
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 8);
    String time(DateTime at) => ml.formatTimeOfDay(TimeOfDay.fromDateTime(at));
    Widget preset(IconData icon, String label, DateTime at) => ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(time(at)),
      onTap: () => Navigator.pop(context, at),
    );

    final picked = await showActionSheet<DateTime>(
      context,
      title: l10n.reminder,
      children: [
        preset(Icons.schedule, l10n.remindInHour, inHour),
        // Offered while there is still an hour to go before it.
        if (now.hour < 17)
          preset(Icons.wb_twilight, l10n.remindTonight, tonight),
        preset(Icons.wb_sunny_outlined, l10n.remindTomorrow, tomorrow),
        ListTile(
          leading: const Icon(Icons.edit_calendar_outlined),
          title: Text(l10n.remindPick),
          onTap: () => Navigator.pop(context, DateTime(0)),
        ),
      ],
    );
    if (picked == null || !mounted) return;
    if (picked.year == 0) {
      await _pickReminderDateTime();
    } else {
      await _setReminder(picked);
    }
  }

  Future<void> _pickReminderDateTime() async {
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
    await _setReminder(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _setReminder(DateTime at) async {
    // A one-off reminder in the past would be saved and never ring.
    if (_n.repeat == ReminderRepeat.none && at.isBefore(DateTime.now())) {
      _fail(AppLocalizations.of(context)!.reminderInPast);
      return;
    }
    setState(() => _n.reminderAt = at);
    final allowed = await ReminderService.requestPermission();
    if (mounted) setState(() => _notificationsOff = !allowed);
  }

  /// Attaches a photo from the gallery or camera, replacing the current one.
  Future<void> _attachPhoto(ImageSource source) async {
    try {
      final picked = await ImageService().pickImage(source);
      if (picked == null || !mounted) return;
      _discardPhotoIfAdded(_n.imagePath);
      _addedPhotos.add(picked);
      setState(() {
        _n.imagePath = picked;
        _error = null;
      });
    } catch (_) {
      // Permission denied, camera error, I/O: the note stays as it was, and
      // the line under the paper says why nothing happened.
      if (mounted) _fail(AppLocalizations.of(context)!.photoPickFailed);
    }
  }

  void _removePhoto() {
    _discardPhotoIfAdded(_n.imagePath);
    setState(() => _n.imagePath = '');
  }

  /// A photo attached earlier in this session and now replaced or removed can
  /// be deleted right away; the note's original photo is the caller's
  /// business (it may still be wanted if the edit is cancelled).
  void _discardPhotoIfAdded(String path) {
    if (_addedPhotos.remove(path)) ImageService.deleteFile(path);
  }

  /// A recording made in the editor replaces the one before it; a take
  /// from this session that is no longer wanted goes straight away.
  void _setRecording(String stored, int ms) {
    _discardAudioIfAdded(_n.audioPath);
    _addedAudio.add(stored);
    setState(() {
      _n
        ..audioPath = stored
        ..audioMs = ms;
      _error = null;
    });
  }

  void _deleteRecording() {
    _discardAudioIfAdded(_n.audioPath);
    setState(() {
      _n
        ..audioPath = ''
        ..audioMs = 0;
    });
  }

  void _discardAudioIfAdded(String path) {
    if (_addedAudio.remove(path)) AudioService.deleteFile(path);
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
      // A print has no paper colour to pick.
      if (t == NoteType.photo) _showColors = false;
    });
  }

  // --- build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPhoto = _n.type == NoteType.photo;
    // Same paper as the card: the print white for a photo, else the colour.
    final paper = isPhoto
        ? printColorOf(context)
        : paperColorOf(context, _n.colorIndex, _n.guid);

    final page = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      // Opening the editor announces what it is for.
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: widget.isNew ? l10n.addNote : l10n.edit,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
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
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
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
                              if (_n.hasPhoto || isPhoto) _photoTile(l10n),
                              _writingArea(l10n),
                              if (_n.type == NoteType.link) _urlField(l10n),
                              if (_n.type == NoteType.checklist)
                                _checklistEditor(l10n),
                              if (_n.type == NoteType.audio)
                                VoiceRecorderPanel(
                                  key: _voice,
                                  stored: _n.audioPath,
                                  length: Duration(milliseconds: _n.audioMs),
                                  onRecorded: _setRecording,
                                  onDelete: _deleteRecording,
                                  onProblem: (p) => _fail(
                                    p == RecordProblem.denied
                                        ? l10n.micDenied
                                        : l10n.recordFailed,
                                  ),
                                  onRecordingChanged: (_) => _clearError(),
                                ),
                              if (_n.type == NoteType.drawing) ...[
                                const SizedBox(height: 8),
                                DrawingEditor(
                                  strokes: _n.strokes,
                                  canvas: _n.canvas,
                                  onChanged: () =>
                                      setState(() => _error = null),
                                  onCanvasChanged: (c) =>
                                      setState(() => _n.canvas = c),
                                ),
                              ],
                              _errorLine(),
                              if (_n.reminderAt != null) _reminderLine(l10n),
                              if (_n.reminderAt != null && _notificationsOff)
                                _notificationsOffLine(l10n),
                              const SizedBox(height: 10),
                              _toolRow(l10n),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                alignment: Alignment.topCenter,
                                child: _showEmoji
                                    ? _emojiStrip()
                                    : _showColors
                                    ? _colorRow(l10n)
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
                    child: KeyboardTappable(
                      circle: true,
                      onActivate: () => setState(() => _n.pinned = !_n.pinned),
                      child: Semantics(
                        button: true,
                        toggled: _n.pinned,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _n.pinned = !_n.pinned);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            child: NotePin(pinned: _n.pinned, seed: _n.guid),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!_readable) return page;
    // Readable: the app's theme in Be Vietnam Pro, so every field on the
    // paper (and its size balancing) follows.
    return Theme(
      data: buildAppTheme(
        fontChoiceById('bevietnam'),
        night: isNight(context),
        pin: pinStyleOf(context),
      ),
      child: page,
    );
  }
}
