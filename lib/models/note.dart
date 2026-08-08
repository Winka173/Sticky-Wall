enum NoteType { normal, link, checklist }

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
    List<ChecklistItem>? checklist,
    this.x = 0.5,
    this.y = 0.5,
  })  : type = type ?? (url.isEmpty ? NoteType.normal : NoteType.link),
        checklist = checklist ?? [];

  final String guid;
  String content;
  String url;
  String emoji;
  NoteType type;

  /// Index into the note-paper palette, or null to derive one from the guid.
  int? colorIndex;

  bool pinned;

  /// When set, a local notification is scheduled and a chip is shown.
  DateTime? reminderAt;

  List<ChecklistItem> checklist;

  DateTime createdAt;

  /// Fractional position on the wall (0..1 of the wall area), so a note keeps
  /// its spot across screen sizes. Only used by the free "wall" view.
  double x;
  double y;

  /// Which board this note lives on.
  String boardId;

  bool get checklistDone =>
      checklist.isNotEmpty && checklist.every((i) => i.done);

  /// A deep copy, so a dialog can edit a working copy and discard it on cancel.
  Note clone() => Note.fromJson(toJson());

  factory Note.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String? ?? '';
    final typeName = json['type'] as String?;
    final type = NoteType.values
            .where((t) => t.name == typeName)
            .cast<NoteType?>()
            .firstOrNull ??
        (url.isEmpty ? NoteType.normal : NoteType.link);

    return Note(
      guid: json['guid'] as String,
      // Tolerate data from the original web app, which stored newlines as <br>.
      content: (json['content'] as String? ?? '').replaceAll('<br>', '\n'),
      url: url,
      type: type,
      emoji: json['emoji'] as String? ?? '',
      colorIndex: json['colorIndex'] as int?,
      pinned: json['pinned'] as bool? ?? false,
      reminderAt: json['reminderAt'] == null
          ? null
          : DateTime.tryParse(json['reminderAt'] as String),
      checklist: (json['checklist'] as List<dynamic>? ?? [])
          .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.tryParse(json['createdAt'] as String) ??
              DateTime.fromMillisecondsSinceEpoch(0),
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      boardId: json['boardId'] as String? ?? 'default',
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
        'checklist': checklist.map((i) => i.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'x': x,
        'y': y,
        'boardId': boardId,
      };
}
