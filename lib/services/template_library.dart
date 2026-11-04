import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';

import '../models/note.dart';
import 'theme_packs.dart';

/// Where a board template is shelved in the gallery.
enum TemplateCategory {
  productivity,
  study,
  creative,
  personal,
  family,
  seasonal,
}

/// A word in English and Vietnamese.
class Bilingual {
  const Bilingual(this.en, this.vi);

  factory Bilingual.fromJson(Map<String, dynamic> json) =>
      Bilingual(json['en'] as String? ?? '', json['vi'] as String? ?? '');

  final String en;
  final String vi;

  String of(String languageCode) => languageCode == 'vi' ? vi : en;
}

/// One thing a template puts on the wall.
class TemplateItem {
  const TemplateItem({
    required this.kind,
    required this.x,
    required this.y,
    this.text = const Bilingual('', ''),
    this.items = const [],
    this.color = 0,
    this.scale = 1.0,
    this.rotation,
    this.paper,
    this.sticker = '',
  });

  factory TemplateItem.fromJson(Map<String, dynamic> json) => TemplateItem(
    kind: json['kind'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    text: json['text'] == null
        ? const Bilingual('', '')
        : Bilingual.fromJson(json['text'] as Map<String, dynamic>),
    items: [
      for (final i in json['items'] as List<dynamic>? ?? const [])
        Bilingual.fromJson(i as Map<String, dynamic>),
    ],
    color: json['color'] as int? ?? 0,
    scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    rotation: (json['rotation'] as num?)?.toDouble(),
    paper: PaperStyle.values.where((p) => p.name == json['paper']).firstOrNull,
    sticker: json['sticker'] as String? ?? '',
  );

  /// label, note, checklist or sticker.
  final String kind;
  final double x;
  final double y;
  final Bilingual text;

  /// A checklist's items.
  final List<Bilingual> items;

  /// Which of the theme's papers (0 = its first); without a theme, an index
  /// into the free papers.
  final int color;
  final double scale;
  final double? rotation;
  final PaperStyle? paper;
  final String sticker;
}

/// A thread a template ties between two of its items.
class TemplateThread {
  const TemplateThread(this.from, this.to, {this.arrow = false, this.label});

  factory TemplateThread.fromJson(Map<String, dynamic> json) => TemplateThread(
    json['from'] as int,
    json['to'] as int,
    arrow: json['arrow'] as bool? ?? false,
    label: json['label'] == null
        ? null
        : Bilingual.fromJson(json['label'] as Map<String, dynamic>),
  );

  final int from;
  final int to;
  final bool arrow;
  final Bilingual? label;
}

/// A board that can be started from: real, editable notes, headings,
/// stickers and threads, plus the theme pack it looks best in.
class BoardTemplateDef {
  const BoardTemplateDef({
    required this.id,
    required this.category,
    required this.theme,
    required this.name,
    required this.description,
    required this.tags,
    required this.items,
    required this.threads,
    this.orientation = 'portrait',
  });

  factory BoardTemplateDef.fromJson(Map<String, dynamic> json) =>
      BoardTemplateDef(
        id: json['id'] as String,
        category: TemplateCategory.values.byName(json['category'] as String),
        theme: json['theme'] as String? ?? '',
        name: Bilingual.fromJson(json['name'] as Map<String, dynamic>),
        description: Bilingual.fromJson(
          json['description'] as Map<String, dynamic>,
        ),
        tags: [for (final t in json['tags'] as List<dynamic>) t as String],
        items: [
          for (final i in json['items'] as List<dynamic>)
            TemplateItem.fromJson(i as Map<String, dynamic>),
        ],
        threads: [
          for (final t in json['threads'] as List<dynamic>? ?? const [])
            TemplateThread.fromJson(t as Map<String, dynamic>),
        ],
        orientation: json['orientation'] as String? ?? 'portrait',
      );

  final String id;
  final TemplateCategory category;

  /// The id of the theme pack it is shown in.
  final String theme;
  final Bilingual name;
  final Bilingual description;
  final List<String> tags;
  final List<TemplateItem> items;
  final List<TemplateThread> threads;
  final String orientation;

  ThemePack? get themePack => themePackById(theme);

  /// The notes and threads this template puts on board [boardId], written
  /// in [languageCode], in [pack]'s papers and ruling (or the free papers
  /// when [pack] is null). Example notes are marked as samples; headings
  /// and stickers are the layout and are not.
  ({List<Note> notes, List<NoteLink> links}) build(
    String boardId,
    String languageCode, {
    ThemePack? pack,
    DateTime? now,
  }) {
    const uuid = Uuid();
    final start = now ?? DateTime.now();
    final notes = <Note>[];
    for (final (i, item) in items.indexed) {
      final type = switch (item.kind) {
        'label' => NoteType.label,
        'checklist' => NoteType.checklist,
        'sticker' => NoteType.sticker,
        _ => NoteType.normal,
      };
      final color = pack?.paperAt(item.color) ?? item.color % 6;
      final ruling = item.paper ?? pack?.paper ?? PaperStyle.plain;
      notes.add(
        Note(
          guid: uuid.v4(),
          content: item.text.of(languageCode),
          type: type,
          boardId: boardId,
          colorIndex: type == NoteType.sticker ? null : color,
          paper: ruling.suits(type) ? ruling : PaperStyle.plain,
          checklist: [
            for (final c in item.items) ChecklistItem(text: c.of(languageCode)),
          ],
          sticker: item.sticker,
          // Headings hold still so notes can be tidied under them.
          locked: type == NoteType.label,
          sample: type == NoteType.normal || type == NoteType.checklist,
          x: item.x,
          y: item.y,
          scale: item.scale,
          rotation: item.rotation,
          // Staggered so the grid and list keep the reading order.
          createdAt: start.subtract(Duration(seconds: items.length - i)),
        ),
      );
    }
    final links = [
      for (final t in threads)
        NoteLink(
          notes[t.from].guid,
          notes[t.to].guid,
          arrow: t.arrow,
          label: t.label?.of(languageCode) ?? '',
          style: pack?.thread ?? ThreadStyle.yarn,
          color: pack?.yarn,
        ),
    ];
    return (notes: notes, links: links);
  }
}

/// The bundled board templates (assets/templates/templates.json).
class TemplateLibrary {
  TemplateLibrary._();

  static const asset = 'assets/templates/templates.json';
  static Future<List<BoardTemplateDef>>? _loading;

  /// The library once it has been read, so a screen opened later shows it
  /// at once instead of waiting a frame.
  static List<BoardTemplateDef>? loaded;

  /// Reads the bundled library once.
  static Future<List<BoardTemplateDef>> load() => _loading ??= rootBundle
      .loadString(asset)
      .then(parse)
      .then((list) => loaded = list);

  static List<BoardTemplateDef> parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return [
      for (final t in json['templates'] as List<dynamic>)
        BoardTemplateDef.fromJson(t as Map<String, dynamic>),
    ];
  }
}
