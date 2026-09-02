import 'draw_stroke.dart';

enum NoteType { normal, link, checklist, drawing }

/// How often a reminder fires again after its first time.
enum ReminderRepeat { none, daily, weekly, monthly }

/// One row of a checklist note.
class ChecklistItem {
  ChecklistItem({required this.text, this.done = false});

  String text;
  bool done;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        text: json['text'] as String? ?? '',
        done: json['done'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {'text': text, 'done': done};
}

/// A single sticky note.
///
/// The [type] is stored explicitly. For data from older versions (and from
/// the original web app) it is inferred: a note with a non-empty [url] is a
/// link, otherwise a normal note.
class Note {
  Note({
    required this.guid,
    required this.content,
    required this.createdAt,
    required this.boardId,
    NoteType? type,
    this.url = '',
    this.emoji = '',
    this.colorIndex,
    this.pinned = false,
    this.reminderAt,
    this.repeat = ReminderRepeat.none,
    List<ChecklistItem>? checklist,
    List<DrawStroke>? strokes,
    this.imagePath = '',
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 1.0,
    this.deletedAt,
    this.completedAt,
  })  : type = type ?? (url.isEmpty ? NoteType.normal : NoteType.link),
        checklist = checklist ?? [],
        strokes = strokes ?? [];

  final String guid;
  String content;
  String url;
  String emoji;
  NoteType type;

  /// Index into the note-paper palette, or null to derive one from the guid.
  int? colorIndex;

  bool pinned;

  /// When set, a local notification is scheduled and a chip is shown. For a
  /// repeating reminder this is the *first* occurrence; see [nextReminder].
  DateTime? reminderAt;
  ReminderRepeat repeat;

  List<ChecklistItem> checklist;

  /// Freehand strokes for a drawing note.
  List<DrawStroke> strokes;

  /// Attached photo reference — the file name inside the app's photo folder
  /// (see `ImageService.resolve`); empty if none.
  String imagePath;

  DateTime createdAt;

  /// Fractional position on the wall (0..1 of the wall area), so a note keeps
  /// its spot across screen sizes. Only used by the free "wall" view.
  double x;
  double y;

  /// Size multiplier on the wall (pinch/handle resize).
  double scale;

  /// Which board this note lives on.
  String boardId;

  /// Set while the note sits in the trash; null for a live note.
  DateTime? deletedAt;

  /// When every item of a checklist was ticked off (null while any is open),
  /// so finished lists can be tidied away automatically.
  DateTime? completedAt;

  bool get isTrashed => deletedAt != null;

  bool get checklistDone =>
      checklist.isNotEmpty && checklist.every((i) => i.done);

  /// The next time the reminder fires: [reminderAt] itself for a one-off, or
  /// the first occurrence at/after [now] for a repeating one (same time of
  /// day, and for weekly/monthly the same weekday / day of month).
  DateTime? nextReminder([DateTime? now]) {
    final first = reminderAt;
    if (first == null || repeat == ReminderRepeat.none) return first;
    now ??= DateTime.now();
    var next = first;
    // Bounded so a corrupt far-past date can't spin forever.
    for (var i = 0; i < 2000 && !next.isAfter(now); i++) {
      next = switch (repeat) {
        ReminderRepeat.daily => next.add(const Duration(days: 1)),
        ReminderRepeat.weekly => next.add(const Duration(days: 7)),
        ReminderRepeat.monthly =>
          DateTime(next.year, next.month + 1, first.day, next.hour, next.minute),
        ReminderRepeat.none => next,
      };
    }
    return next;
  }

  /// A deep copy, so a dialog can edit a working copy and discard it on cancel.
  Note clone() => Note.fromJson(toJson());

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory Note.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String? ?? '';
    final typeName = json['type'] as String?;
    final type = NoteType.values
            .where((t) => t.name == typeName)
            .cast<NoteType?>()
            .firstOrNull ??
        (url.isEmpty ? NoteType.normal : NoteType.link);
    final repeatName = json['repeat'] as String?;
    final repeat = ReminderRepeat.values
            .where((r) => r.name == repeatName)
            .cast<ReminderRepeat?>()
            .firstOrNull ??
        ReminderRepeat.none;

    return Note(
      guid: json['guid'] as String,
      // Tolerate data from the original web app, which stored newlines as <br>.
      content: (json['content'] as String? ?? '').replaceAll('<br>', '\n'),
      url: url,
      type: type,
      emoji: json['emoji'] as String? ?? '',
      colorIndex: json['colorIndex'] as int?,
      pinned: json['pinned'] as bool? ?? false,
      reminderAt: _date(json['reminderAt']),
      repeat: repeat,
      checklist: (json['checklist'] as List<dynamic>? ?? [])
          .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      strokes: (json['strokes'] as List<dynamic>? ?? [])
          .map((e) => DrawStroke.fromJson(e as Map<String, dynamic>))
          .toList(),
      imagePath: json['imagePath'] as String? ?? '',
      createdAt:
          _date(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      boardId: json['boardId'] as String? ?? 'default',
      deletedAt: _date(json['deletedAt']),
      completedAt: _date(json['completedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'guid': guid,
        'content': content,
        'url': url,
        'type': type.name,
        'emoji': emoji,
        'colorIndex': colorIndex,
        'pinned': pinned,
        'reminderAt': reminderAt?.toIso8601String(),
        'repeat': repeat.name,
        'checklist': checklist.map((i) => i.toJson()).toList(),
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
        'x': x,
        'y': y,
        'scale': scale,
        'boardId': boardId,
        'deletedAt': deletedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };
}

/// A piece of red yarn tied between two pins on the wall. Unordered: the same
/// pair is one link whichever end you started from.
class NoteLink {
  const NoteLink(this.a, this.b);

  final String a;
  final String b;

  bool connects(String guid) => a == guid || b == guid;

  bool same(String x, String y) => (a == x && b == y) || (a == y && b == x);

  factory NoteLink.fromJson(Map<String, dynamic> json) =>
      NoteLink(json['a'] as String, json['b'] as String);

  Map<String, dynamic> toJson() => {'a': a, 'b': b};
}
