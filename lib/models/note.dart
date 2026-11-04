import 'draw_stroke.dart';

/// What kind of note a card is. Stored by name in JSON; legacy notes without
/// a type are inferred from their fields (see [Note.fromJson]).
///
/// [photo] is a picture pinned straight on the wall — a photo print rather
/// than a sheet of paper, with an optional caption. It is still a [Note], so
/// dragging, resizing, threads, boards and the trash all work the same.
///
/// [label] is a strip of tape with a word or two on it — a heading for a
/// column or corner of a planning board. No pin, no body: just the name.
///
/// [audio] is a voice note, drawn as a little cassette with a play button;
/// its recording lives in a file named by [Note.audioPath].
///
/// [sticker] is a sticker stuck straight on the wall — an emoji, a rubber
/// stamp or a doodle named by [Note.sticker]; no paper, no pin. New types go
/// at the end: the type filter stores an index (see `NoteStorage.typeFilter`).
enum NoteType { normal, link, checklist, drawing, photo, label, audio, sticker }

/// How a photo print is framed. [print] is the plain white border every
/// version has drawn; the others came with 1.4.1's memory walls.
enum PhotoFrame {
  print,
  polaroid,
  film,
  vintage,
  torn,
  rounded,
  scrapbook;

  /// Film, vintage, torn and scrapbook are Sticky Wall Pro's; a print in one
  /// keeps it without Pro.
  bool get pro => switch (this) {
    print || polaroid || rounded => false,
    _ => true,
  };
}

/// The ruling printed on a sheet of note paper. Plain is the classic sticky
/// note; the others are Sticky Wall Pro's.
enum PaperStyle {
  plain,
  lined,
  grid,
  dots,
  indexCard,
  notebook;

  bool get pro => this != plain;

  /// Ruled across, line by line: these only suit a note of running text,
  /// whose lines they can follow; lists and links take squares or dots.
  bool get ruled => this == lined || this == indexCard || this == notebook;

  /// Whether a note of [type] can use this paper.
  bool suits(NoteType type) => switch (type) {
    NoteType.normal => true,
    NoteType.link || NoteType.checklist => !ruled,
    _ => this == plain,
  };
}

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
    this.canvas = const DrawCanvas(),
    this.imagePath = '',
    this.audioPath = '',
    this.audioMs = 0,
    this.paper = PaperStyle.plain,
    this.sticker = '',
    this.sample = false,
    this.frame = PhotoFrame.print,
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 1.0,
    this.rotation,
    this.locked = false,
    this.stack,
    this.deletedAt,
    this.completedAt,
  }) : type = type ?? (url.isEmpty ? NoteType.normal : NoteType.link),
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

  /// The paper the strokes sit on (tone + guide pattern); drawing notes only.
  DrawCanvas canvas;

  /// The attached photo — a file name inside the app's photo folder (see
  /// `ImageService.resolve`), or empty. A [NoteType.photo] note needs one;
  /// any other type may carry one as well.
  String imagePath;

  bool get hasPhoto => imagePath.isNotEmpty;

  /// A voice note's recording — a file name inside the app's audio folder
  /// (see `AudioService.resolve`), or empty. Only [NoteType.audio] keeps one.
  String audioPath;

  /// How long the recording runs, in milliseconds (0 when unknown), so the
  /// card can say so without opening the file.
  int audioMs;

  bool get hasAudio => audioPath.isNotEmpty;

  /// The ruling on the paper (sheets of paper only: plain, link and
  /// checklist notes).
  PaperStyle paper;

  /// Which sticker a [NoteType.sticker] is (see `stickers` in
  /// widgets/stickers.dart); empty for every other type.
  String sticker;

  /// Example content put there by a board template: "Clear the examples"
  /// takes it away and leaves the layout (headings, stickers). Editing the
  /// note makes it the user's own.
  bool sample;

  /// The frame of a photo print ([NoteType.photo]).
  PhotoFrame frame;

  DateTime createdAt;

  /// Fractional position on the wall (0..1 of the wall area), so a note keeps
  /// its spot across screen sizes. Only used by the free "wall" view.
  double x;
  double y;

  /// Size multiplier on the wall (pinch/handle resize).
  double scale;

  /// How far the card is turned on the wall, in radians (clockwise), once the
  /// user has spun it with the rotate handle. Null means "as it was stuck":
  /// a slight hand-placed tilt derived from the guid, straightened while the
  /// note is pinned (see `noteAngle`).
  double? rotation;

  /// Held in place on the wall: it cannot be dragged, turned or resized, and
  /// a tidy-up flows the other notes around it. For headings and anything
  /// else that must not be nudged by accident.
  bool locked;

  /// Notes sharing a stack id lie in one pile on the wall: one place, the
  /// top card showing, the rest peeking out under it. Null for a lone note.
  String? stack;

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
        ReminderRepeat.monthly => DateTime(
          next.year,
          next.month + 1,
          first.day,
          next.hour,
          next.minute,
        ),
        ReminderRepeat.none => next,
      };
    }
    return next;
  }

  /// A deep copy, so a dialog can edit a working copy and discard it on cancel.
  Note clone() => Note.fromJson(toJson());

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  /// The photo from JSON: `imagePath`, or — for data saved by the short-lived
  /// builds that allowed several photos per note — the first of `images`.
  static String _imagePath(Map<String, dynamic> json) {
    final single = json['imagePath'] as String? ?? '';
    if (single.isNotEmpty) return single;
    final list = json['images'];
    if (list is List) {
      for (final e in list) {
        if (e is String && e.isNotEmpty) return e;
      }
    }
    return '';
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String? ?? '';
    final typeName = json['type'] as String?;
    final type =
        NoteType.values
            .where((t) => t.name == typeName)
            .cast<NoteType?>()
            .firstOrNull ??
        (url.isEmpty ? NoteType.normal : NoteType.link);
    final repeatName = json['repeat'] as String?;
    final repeat =
        ReminderRepeat.values
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
      canvas: DrawCanvas.fromJson(json['canvas'] as Map<String, dynamic>?),
      imagePath: _imagePath(json),
      audioPath: json['audioPath'] as String? ?? '',
      audioMs: (json['audioMs'] as num?)?.toInt() ?? 0,
      paper:
          PaperStyle.values.where((p) => p.name == json['paper']).firstOrNull ??
          PaperStyle.plain,
      sticker: json['sticker'] as String? ?? '',
      sample: json['sample'] as bool? ?? false,
      // An unknown frame (from a newer version) falls back to the plain
      // print rather than losing the photo.
      frame:
          PhotoFrame.values.where((f) => f.name == json['frame']).firstOrNull ??
          PhotoFrame.print,
      createdAt:
          _date(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble(),
      locked: json['locked'] as bool? ?? false,
      stack: json['stack'] as String?,
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
    'canvas': canvas.toJson(),
    'imagePath': imagePath,
    if (audioPath.isNotEmpty) 'audioPath': audioPath,
    if (audioMs > 0) 'audioMs': audioMs,
    if (paper != PaperStyle.plain) 'paper': paper.name,
    if (sticker.isNotEmpty) 'sticker': sticker,
    if (sample) 'sample': true,
    if (frame != PhotoFrame.print) 'frame': frame.name,
    'createdAt': createdAt.toIso8601String(),
    'x': x,
    'y': y,
    'scale': scale,
    'rotation': rotation,
    'locked': locked,
    if (stack != null) 'stack': stack,
    'boardId': boardId,
    'deletedAt': deletedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };
}

/// What a thread is made of. Yarn comes with the app; the others are Sticky
/// Wall Pro's.
enum ThreadStyle {
  yarn,
  twine,
  ribbon,
  dashed,
  beads;

  bool get pro => this != yarn;
}

/// A piece of yarn tied between two pins on the wall. Unordered for the
/// purpose of identity: the same pair is one link whichever end you started
/// from — but [arrow] points from [a] to [b].
class NoteLink {
  const NoteLink(
    this.a,
    this.b, {
    this.color,
    this.label = '',
    this.arrow = false,
    this.style = ThreadStyle.yarn,
  });

  final String a;
  final String b;

  /// ARGB yarn colour, or null for the classic red.
  final int? color;

  /// A word or two written on a paper tag hung from the middle of the thread.
  final String label;

  /// Whether the [b] end carries an arrowhead (a dependency, a flow).
  final bool arrow;

  final ThreadStyle style;

  bool connects(String guid) => a == guid || b == guid;

  bool same(String x, String y) => (a == x && b == y) || (a == y && b == x);

  NoteLink copyWith({
    int? color,
    bool clearColor = false,
    String? label,
    bool? arrow,
    ThreadStyle? style,
  }) => NoteLink(
    a,
    b,
    color: clearColor ? null : (color ?? this.color),
    label: label ?? this.label,
    arrow: arrow ?? this.arrow,
    style: style ?? this.style,
  );

  factory NoteLink.fromJson(Map<String, dynamic> json) => NoteLink(
    json['a'] as String,
    json['b'] as String,
    color: json['color'] as int?,
    label: json['label'] as String? ?? '',
    arrow: json['arrow'] as bool? ?? false,
    style:
        ThreadStyle.values.where((s) => s.name == json['style']).firstOrNull ??
        ThreadStyle.yarn,
  );

  Map<String, dynamic> toJson() => {
    'a': a,
    'b': b,
    if (color != null) 'color': color,
    if (label.isNotEmpty) 'label': label,
    if (arrow) 'arrow': true,
    if (style != ThreadStyle.yarn) 'style': style.name,
  };
}
