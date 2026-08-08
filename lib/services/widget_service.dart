import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/note.dart';

/// Pushes the current board's pinned notes to the home-screen widget.
/// All calls are guarded so the app runs fine where no widget exists
/// (iOS without a widget extension, web, tests).
class WidgetService {
  static const _androidName = 'StickyWidgetProvider';
  static const _iOSName = 'StickyWidget';

  String? _lastPayload;

  Future<void> update(String boardName, List<Note> pinned) async {
    final title = boardName.isEmpty ? 'Sticky Wall' : boardName;
    final lines = [
      for (var i = 0; i < 3; i++)
        i < pinned.length ? _label(pinned[i]) : '',
    ];
    // Skip redundant pushes (e.g. while typing in search, which doesn't
    // change the pinned set) so we don't spam the platform channel.
    final payload = [title, ...lines].join('');
    if (payload == _lastPayload) return;
    _lastPayload = payload;

    try {
      await HomeWidget.saveWidgetData<String>('title', title);
      for (var i = 0; i < 3; i++) {
        await HomeWidget.saveWidgetData<String>('line${i + 1}', lines[i]);
      }
      await HomeWidget.updateWidget(
          androidName: _androidName, iOSName: _iOSName);
    } catch (e) {
      debugPrint('Widget update skipped: $e');
    }
  }

  String _label(Note note) {
    final text = switch (note.type) {
      NoteType.checklist => note.content.isEmpty ? 'Checklist' : note.content,
      NoteType.drawing => note.content.isEmpty ? 'Drawing' : note.content,
      _ => note.content,
    };
    final prefix = note.emoji.isEmpty ? '' : '${note.emoji} ';
    return '$prefix$text';
  }
}
