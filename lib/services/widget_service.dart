import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/note.dart';
import '../theme.dart';
import '../util/rich_note.dart';
import 'note_storage.dart';

/// What a tap on the home-screen widget asks for (see [WidgetService.taps]).
sealed class WidgetTap {
  const WidgetTap();

  /// Reads the link the widget opened the app with; null for a plain tap.
  static WidgetTap? parse(Uri? uri) {
    if (uri == null || uri.scheme != WidgetService.scheme) return null;
    final segments = uri.pathSegments;
    return switch (uri.host) {
      'new' => WidgetNewNote(uri.queryParameters['board']),
      'note' when segments.isNotEmpty => WidgetOpenNote(segments.first),
      _ => null,
    };
  }
}

/// The widget's + button: a new note on [boardId] (the board it shows).
class WidgetNewNote extends WidgetTap {
  const WidgetNewNote(this.boardId);
  final String? boardId;
}

/// A line of the widget: that note.
class WidgetOpenNote extends WidgetTap {
  const WidgetOpenNote(this.guid);
  final String guid;
}

/// Pushes a board's notes (pinned or newest) to the home-screen widget, with
/// the colours and text size chosen in Customize.
/// All calls are guarded so the app runs fine where no widget exists
/// (iOS without a widget extension, web, tests).
class WidgetService {
  static const _androidName = 'StickyWidgetProvider';
  static const _iOSName = 'StickyWidget';

  /// The widget opens the app with `stickywall://new?board=<id>` (its +
  /// button) or `stickywall://note/<guid>` (a line).
  static const scheme = 'stickywall';

  static bool get _hasWidget =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Taps on the widget's + button and lines: the one that launched the app
  /// first, then each one while it runs. Nothing where there is no widget.
  static Stream<WidgetTap> taps() async* {
    if (!_hasWidget) return;
    try {
      final first = WidgetTap.parse(
        await HomeWidget.initiallyLaunchedFromHomeWidget(),
      );
      if (first != null) yield first;
      await for (final uri in HomeWidget.widgetClicked) {
        final tap = WidgetTap.parse(uri);
        if (tap != null) yield tap;
      }
    } catch (e) {
      debugPrint('Widget taps skipped: $e');
    }
  }

  /// The app group the iOS widget extension shares with the app (see
  /// ios/StickyWidget). Harmless elsewhere.
  static const appGroup = 'group.com.winka.stickyWall';

  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(appGroup);
    } catch (e) {
      debugPrint('Widget app group skipped: $e');
    }
  }

  /// Puts a picture of the board on the widget in place of the text lines:
  /// the PNG goes where the widget can read it (the app's files on Android,
  /// the shared app group on iOS) and its path is handed over under `wall`.
  /// Returns whether that worked (no widget host, no file system → false).
  static Future<bool> showWallImage(Uint8List png) async {
    try {
      await HomeWidget.saveFile('wall', png, extension: 'png');
      await HomeWidget.updateWidget(
        androidName: _androidName,
        iOSName: _iOSName,
      );
      return true;
    } catch (e) {
      debugPrint('Widget image skipped: $e');
      return false;
    }
  }

  /// How many lines the widget can show at its largest; a smaller widget
  /// shows as many as fit.
  static const maxLines = 6;

  String? _lastPayload;

  /// What the widget lists for [content] on board [boardId]: its pinned
  /// notes, or its newest notes (tape labels are headings and stickers
  /// decoration, not notes, so they are left out).
  static List<Note> notesFor(
    List<Note> all,
    String boardId,
    WidgetContent content,
  ) {
    final onBoard = all.where((n) => n.boardId == boardId && !n.isTrashed);
    if (content != WidgetContent.newest) {
      return onBoard.where((n) => n.pinned).toList(growable: false);
    }
    return onBoard
        .where((n) => n.type != NoteType.label && n.type != NoteType.sticker)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// [notes] are listed in order, up to [maxLines]; [empty] is shown when
  /// there are none. [checklistLabel], [drawingLabel], [photoLabel] and
  /// [audioLabel] stand in for untitled to-do, drawing, photo and voice
  /// notes; the caller passes every word already localized. [boardId] is
  /// where the widget's + button puts a new note.
  Future<void> update({
    required String title,
    String boardId = '',
    required List<Note> notes,
    required String empty,
    required String checklistLabel,
    required String drawingLabel,
    required String photoLabel,
    String audioLabel = '',
    WidgetContent content = WidgetContent.pinned,
    WidgetLook look = WidgetLook.wall,
    WidgetTextSize textSize = WidgetTextSize.normal,
  }) async {
    final lines = [
      for (var i = 0; i < maxLines; i++)
        i < notes.length
            ? lineFor(
                notes[i],
                checklistLabel,
                drawingLabel,
                photoLabel,
                audioLabel,
              )
            : '',
    ];
    // Each line opens its note and wears a dot of its paper.
    final ids = [
      for (var i = 0; i < maxLines; i++) i < notes.length ? notes[i].guid : '',
    ];
    final colors = [
      for (var i = 0; i < maxLines; i++)
        i < notes.length ? '${dotColor(notes[i]).toARGB32()}' : '',
    ];
    // Skip redundant pushes (e.g. while typing in search, which doesn't
    // change what the widget lists) so we don't spam the platform channel.
    final payload = [
      title,
      boardId,
      empty,
      content.name,
      look.name,
      textSize.name,
      ...lines,
      ...ids,
      ...colors,
    ].join('\u0000');
    if (payload == _lastPayload) return;
    _lastPayload = payload;

    try {
      await HomeWidget.saveWidgetData<String>('title', title);
      await HomeWidget.saveWidgetData<String>('boardId', boardId);
      await HomeWidget.saveWidgetData<String>('empty', empty);
      await HomeWidget.saveWidgetData<String>('mode', content.name);
      await HomeWidget.saveWidgetData<String>('look', look.name);
      await HomeWidget.saveWidgetData<String>('textSize', textSize.name);
      for (var i = 0; i < maxLines; i++) {
        await HomeWidget.saveWidgetData<String>('line${i + 1}', lines[i]);
        await HomeWidget.saveWidgetData<String>('id${i + 1}', ids[i]);
        await HomeWidget.saveWidgetData<String>('color${i + 1}', colors[i]);
      }
      await HomeWidget.updateWidget(
        androidName: _androidName,
        iOSName: _iOSName,
      );
    } catch (e) {
      debugPrint('Widget update skipped: $e');
    }
  }

  /// The dot in front of a line: the note's paper, or a print's white.
  static Color dotColor(Note note) => note.type == NoteType.photo
      ? AppColors.printPaper
      : noteColor(note.colorIndex, note.guid);

  /// One line of the widget: the note's emoji and words, or the name of
  /// its kind when it has none. A to-do list also says how far along it is
  /// ("Shopping · 2/5").
  static String lineFor(
    Note note,
    String checklistLabel,
    String drawingLabel,
    String photoLabel,
    String audioLabel,
  ) {
    final text = switch (note.type) {
      NoteType.checklist =>
        note.content.isEmpty ? checklistLabel : note.content,
      NoteType.drawing => note.content.isEmpty ? drawingLabel : note.content,
      NoteType.photo => note.content.isEmpty ? photoLabel : note.content,
      NoteType.audio => note.content.isEmpty ? audioLabel : note.content,
      _ => plainNoteText(note.content),
    };
    final prefix = note.emoji.isEmpty ? '' : '${note.emoji} ';
    final items = note.checklist.where((i) => i.text.trim().isNotEmpty);
    final progress = note.type == NoteType.checklist && items.isNotEmpty
        ? ' · ${items.where((i) => i.done).length}/${items.length}'
        : '';
    return '$prefix$text$progress';
  }
}
