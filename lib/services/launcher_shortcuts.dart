import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';

import '../l10n/app_localizations.dart';
import '../models/note.dart';

/// The shortcuts a long press on the app icon offers: a new note, a new
/// to-do list or a voice note, straight into the editor. Phones only.
class LauncherShortcuts {
  LauncherShortcuts({QuickActions? actions})
    : _actions = actions ?? const QuickActions();

  final QuickActions _actions;

  /// Shortcut ids (kept stable: launchers remember pinned shortcuts by
  /// them) and the kind of note each starts.
  static const kinds = <String, NoteType>{
    'new_text': NoteType.normal,
    'new_checklist': NoteType.checklist,
    'new_voice': NoteType.audio,
  };

  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Calls [onPick] with the kind of note a shortcut asks for, also when the
  /// app was started by one.
  void listen(void Function(NoteType kind) onPick) {
    if (!supported) return;
    _actions.initialize((id) {
      final kind = kinds[id];
      if (kind != null) onPick(kind);
    });
  }

  /// Names the shortcuts in the app's language.
  Future<void> label(AppLocalizations l10n) async {
    if (!supported) return;
    try {
      await _actions.setShortcutItems([
        ShortcutItem(
          type: 'new_text',
          localizedTitle: l10n.shortcutNewNote,
          icon: 'ic_shortcut_note',
        ),
        ShortcutItem(
          type: 'new_checklist',
          localizedTitle: l10n.shortcutNewList,
          icon: 'ic_shortcut_checklist',
        ),
        ShortcutItem(
          type: 'new_voice',
          localizedTitle: l10n.shortcutVoiceNote,
          icon: 'ic_shortcut_voice',
        ),
      ]);
    } catch (e) {
      debugPrint('Launcher shortcuts unavailable: $e');
    }
  }
}
