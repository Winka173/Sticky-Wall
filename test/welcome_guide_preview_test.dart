// Screenshot generator for the first-run guide and How to use, not a
// regression test. Skipped unless asked for:
//   flutter test test/welcome_guide_preview_test.dart --dart-define=GUIDE_CAPTURE=true
// The pictures land in output/first_run_guide/ (ignored by git).
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/theme.dart';
import 'package:sticky_wall/welcome/how_to_use.dart';
import 'package:sticky_wall/welcome/welcome_guide.dart';

import 'preview_fonts.dart';

void main() {
  const capture = bool.fromEnvironment('GUIDE_CAPTURE');
  const runs = [
    (Size(390, 844), 1.0, 'en', false),
    (Size(320, 640), 1.0, 'en', false),
    (Size(320, 640), 2.0, 'vi', false),
    (Size(390, 844), 1.0, 'vi', true),
    (Size(1280, 800), 1.0, 'en', false),
  ];
  for (final (size, text, language, night) in runs) {
    final name =
        '${size.width.toInt()}_${(text * 100).toInt()}_$language'
        '${night ? '_night' : ''}';
    testWidgets('guide screenshots $name', skip: !capture, (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = text;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await loadPreviewFonts();
      SharedPreferences.setMockInitialValues({});
      final storage = await NoteStorage.create();
      await storage.saveNotes([
        Note(
          guid: 's1',
          content: language == 'vi' ? 'Ghi chú mẫu' : 'A sample note',
          createdAt: DateTime(2026),
          boardId: 'default',
          sample: true,
          x: .2,
          y: .2,
        ),
      ]);
      await storage.setViewMode(ViewMode.wall);
      await storage.setLanguageCode(language);
      await storage.setWelcomePending(true);
      final settings = SettingsController(storage);
      if (night) settings.setNightMode(NightMode.on);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: StickyWallApp(
            settings: settings,
            notes: NotesController(storage, ReminderService()),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold).first);
        for (final wall in walls) {
          await precacheImage(AssetImage(wall.asset), context);
        }
      });
      await tester.pumpAndSettle();

      Future<void> shot(String step) async {
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          final file = File('output/first_run_guide/${name}_$step.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      final primary = find.byKey(const Key('guide-primary'));
      final next = find.byKey(const Key('guide-practice-next'));
      await shot('1a_scattered');
      await tap(primary);
      await shot('1b_wall');
      await tap(primary);
      await shot('2a_add');
      await tap(find.byKey(const Key('guide-practice-add')));
      await shot('2b_move');
      await tap(next);
      await shot('2c_tie');
      await tap(next);
      await shot('2d_done');
      await tap(primary);
      await shot('3_choose');
      await tap(find.byKey(const Key('guide-choice-blank')));
      await shot('3_choose_blank');
      // Skip leaves the guide with nothing changed.
      await tap(find.byKey(const Key('guide-skip')));

      final context = tester.element(find.byType(Scaffold).first);
      final nav = Navigator.of(context);
      // Pushed, not awaited: the pages stay open for their pictures.
      unawaited(HowToUsePage.open(context));
      await shot('4_how_to_use');
      unawaited(
        WelcomeGuide.open(
          tester.element(find.byType(HowToUsePage)),
          replay: true,
        ),
      );
      await tester.pumpAndSettle();
      await tap(primary);
      await tap(primary);
      for (var i = 0; i < 3; i++) {
        await tap(next);
      }
      await tap(primary);
      await shot('4_replay_last');
      await tap(primary);
      for (var i = 0; i < 7; i++) {
        if (i == 0) {
          await tester.scrollUntilVisible(
            find.byKey(const Key('manual-topic-0')),
            200,
            scrollable: find
                .descendant(
                  of: find.byType(HowToUsePage),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tap(find.byKey(const Key('manual-topic-0')));
        } else {
          await tap(find.byKey(const Key('manual-next')));
        }
        await shot('5_topic_${i + 1}');
      }
      nav.popUntil((r) => r.isFirst);
      await tester.pumpAndSettle();
    });
  }
}
