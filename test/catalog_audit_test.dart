import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/services/template_library.dart';
import 'package:sticky_wall/services/theme_packs.dart';
import 'package:sticky_wall/theme.dart';

/// Every template and every theme, on the smallest phone the app supports
/// (320 dp) with text at 200 %, in English and Vietnamese: nothing may
/// overflow or throw, and every theme's paper must keep note text readable.
void main() {
  double luminance(Color c) => c.computeLuminance();
  double contrast(Color a, Color b) {
    final x = luminance(a) + 0.05;
    final y = luminance(b) + 0.05;
    return x > y ? x / y : y / x;
  }

  test('every theme keeps ink readable on its papers (WCAG 4.5:1)', () {
    final weak = <String>[];
    for (final pack in themePacks) {
      for (final i in pack.papers) {
        final paper = AppColors.notePapers[i % AppColors.notePapers.length];
        final ratio = contrast(AppColors.ink, paper);
        if (ratio < 4.5) {
          weak.add('${pack.id}: paper $i ${ratio.toStringAsFixed(2)}');
        }
      }
    }
    expect(weak, isEmpty);
  });

  for (final lang in ['en', 'vi']) {
    testWidgets('every template and theme lays out at 320 dp, text 200 % '
        '($lang)', (tester) async {
      tester.view.physicalSize = const Size(640, 1400);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final templates = (await tester.runAsync(TemplateLibrary.load))!;
      expect(templates, isNotEmpty);
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      await storage.saveBoards([Board(id: 'default', name: '')]);
      await storage.saveNotes([]);
      await storage.setViewMode(ViewMode.wall);
      await storage.setLanguageCode(lang);
      final notes = NotesController(storage, ReminderService());
      await tester.pumpWidget(
        StickyWallApp(settings: SettingsController(storage), notes: notes),
      );
      await tester.pumpAndSettle();

      final broken = <String>[];
      Future<void> check(String what) async {
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final e = tester.takeException();
        if (e != null) broken.add('$what: $e'.split('\n').first);
      }

      for (final t in templates) {
        notes.addBoardFromTemplate(t, lang);
        await check('template ${t.id}');
        for (final mode in [ViewMode.grid, ViewMode.list]) {
          notes.viewMode = mode;
          await check('template ${t.id} $mode');
        }
        notes
          ..viewMode = ViewMode.wall
          ..deleteBoard(notes.currentBoardId);
      }
      for (final pack in themePacks) {
        notes.applyTheme(notes.currentBoardId, pack);
        await check('theme ${pack.id}');
      }
      expect(broken, isEmpty);
    });
  }
}
