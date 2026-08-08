enum NoteType { normal, link }

/// A single sticky note. A note with a non-empty [url] is a "link" note
/// (a bookmark with a label); otherwise it is a "normal" free-text note.
class Note {
  Note({
    required this.guid,
    required this.content,
    this.url = '',
    this.emoji = '',
  });

  final String guid;
  String content;
  String url;

  /// Optional emote sticker shown on the note.
  String emoji;

  NoteType get type => url.isEmpty ? NoteType.normal : NoteType.link;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        guid: json['guid'] as String,
        // Tolerate data exported from the original web app, which stored
        // newlines as <br>.
        content: (json['content'] as String? ?? '').replaceAll('<br>', '\n'),
        url: json['url'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'guid': guid,
        'content': content,
        'url': url,
        'emoji': emoji,
      };
}
