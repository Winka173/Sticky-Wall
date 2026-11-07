// Regenerates the manual's static pictures from the REAL app widgets.
// flutter test test/manual_assets_test.dart --dart-define=MANUAL_ASSETS=true --dart-define=STICKY_SYNC=true
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/screens/memory_wall_sheet.dart';
import 'package:sticky_wall/services/image_service.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/services/sync/sync_service.dart';
import 'package:sticky_wall/theme.dart';
import 'package:sticky_wall/widgets/add_note_button.dart';
import 'package:sticky_wall/widgets/board_bar.dart';
import 'package:sticky_wall/widgets/board_picker.dart';
import 'package:sticky_wall/widgets/note_dialog.dart';
import 'package:sticky_wall/widgets/note_views.dart';
import 'package:sticky_wall/widgets/settings_sheet.dart';

import 'manual_asset_sources.dart';
import 'preview_fonts.dart';

void main() {
  for (final lang in ['en', 'vi']) {
    testWidgets(
      'manual pictures from current app: $lang',
      skip: !const bool.fromEnvironment('MANUAL_ASSETS'),
      (tester) async {
        tester.view.physicalSize = const Size(430, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await loadPreviewFonts();
        SharedPreferences.setMockInitialValues({});
        final storage = await NoteStorage.create();
        await storage.setLanguageCode(lang);
        await storage.setWelcomePending(false);
        await storage.setTipsPending(false);
        await storage.setViewMode(ViewMode.wall);
        await storage.saveBoards([
          Board(id: 'default', name: lang == 'vi' ? 'Ý tưởng' : 'Ideas'),
          Board(id: 'work', name: lang == 'vi' ? 'Công việc' : 'Work'),
        ]);
        final fixtures = [
          Note(
            guid: 'guide-a',
            sample: true,
            boardId: 'default',
            content: lang == 'vi' ? 'Một ý tưởng nhỏ' : 'A little idea',
            createdAt: DateTime(2026),
            x: .08,
            y: .18,
          ),
          Note(
            guid: 'guide-b',
            boardId: 'default',
            content: lang == 'vi' ? 'Tưới cây' : 'Water the plants',
            createdAt: DateTime(2026),
            x: .7,
            y: .42,
            colorIndex: 1,
          ),
        ];
        await storage.saveNotes(fixtures);
        await storage.saveLinks([NoteLink('guide-a', 'guide-b')]);
        final notes = NotesController(storage, ReminderService());
        final previousSync = SyncService.instance;
        final sync = SyncService(
          prefs: await SharedPreferences.getInstance(),
          notes: notes,
        );
        SyncService.instance = sync;
        addTearDown(() {
          SyncService.instance = previousSync;
          sync.dispose();
        });
        final settings = SettingsController(storage);
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: StickyWallApp(notes: notes, settings: settings),
          ),
        );
        await tester.pumpAndSettle();
        BuildContext ctx() => tester.element(find.byType(Scaffold).first);
        final l = AppLocalizations.of(ctx())!;
        await tester.runAsync(() async {
          for (final wall in walls) {
            await precacheImage(AssetImage(wall.asset), ctx());
          }
        });
        final manifest = <String, Object>{};

        Future<void> shot(
          String id,
          Finder target, {
          List<Rect> extra = const [],
          (Offset, Offset)? arrow,
          Rect? focusOverride,
          Rect? contextBounds,
        }) async {
          await tester.pumpAndSettle();
          expect(target, findsWidgets, reason: 'Missing real UI target: $id');
          await tester.ensureVisible(target.first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: id);
          var element = tester.element(target.first);
          if (element.widget is Text) {
            element.visitAncestorElements((ancestor) {
              if (ancestor.widget is ButtonStyleButton ||
                  ancestor.widget is ListTile ||
                  ancestor.widget is InkWell) {
                element = ancestor;
                return false;
              }
              return true;
            });
          }
          final rect =
              (focusOverride ??
                      tester.getRect(
                        find.byElementPredicate((e) => identical(e, element)),
                      ))
                  .inflate(5)
                  .intersect(const Rect.fromLTWH(2, 2, 426, 896));
          final targets = [rect, ...extra];
          var focus = targets.reduce((a, b) => a.expandToInclude(b));
          if (contextBounds != null) {
            focus = focus.expandToInclude(contextBounds);
          }
          final width = math.max(300.0, focus.width + 36).clamp(300.0, 430.0);
          final height = (focus.height + 108).clamp(170.0, 500.0);
          final crop = Rect.fromLTWH(
            (focus.center.dx - width / 2).clamp(0.0, 430 - width),
            (focus.center.dy - height / 2).clamp(0.0, 900 - height),
            width,
            height,
          );
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder)
              ..scale(2)
              ..translate(-crop.left, -crop.top);
            canvas.drawImageRect(
              image,
              const Rect.fromLTWH(0, 0, 860, 1800),
              const Rect.fromLTWH(0, 0, 430, 900),
              Paint(),
            );
            var shade = Path()..addRect(const Rect.fromLTWH(0, 0, 430, 900));
            for (final r in targets) {
              shade = Path.combine(
                PathOperation.difference,
                shade,
                Path()..addRRect(
                  RRect.fromRectAndRadius(r, const Radius.circular(10)),
                ),
              );
            }
            canvas.drawPath(shade, Paint()..color = const Color(0x99000000));
            for (final r in targets) {
              final shape = RRect.fromRectAndRadius(
                r,
                const Radius.circular(10),
              );
              canvas.drawRRect(
                shape,
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 8
                  ..color = AppColors.accent.withValues(alpha: .4)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
              );
              canvas.drawRRect(
                shape,
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2.5
                  ..color = AppColors.accent,
              );
            }
            if (arrow case (final from, final to)) {
              final pen = Paint()
                ..color = AppColors.accent
                ..strokeWidth = 3
                ..strokeCap = StrokeCap.round;
              canvas.drawLine(from, to, pen);
              final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
              for (final turn in [-.55, .55]) {
                canvas.drawLine(
                  to,
                  to -
                      Offset(math.cos(angle + turn), math.sin(angle + turn)) *
                          12,
                  pen,
                );
              }
            }
            final picture = recorder.endRecording();
            final output = await picture.toImage(
              (width * 2).ceil(),
              (height * 2).ceil(),
            );
            final bytes = (await output.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            final file = File('assets/manual/$lang/$id.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes.buffer.asUint8List());
            manifest[id] = {
              'focus': [rect.left, rect.top, rect.width, rect.height],
              'crop': [crop.left, crop.top, width, height],
              'target': target.toString(),
            };
            image.dispose();
            output.dispose();
            picture.dispose();
          });
        }

        void close() => Navigator.of(ctx()).pop();
        Future<void> tap(Finder finder) async {
          await tester.ensureVisible(finder.first);
          await tester.tap(finder.first);
          await tester.pumpAndSettle();
        }

        Finder card(String id) => find.byWidgetPredicate(
          (w) => w is StickyNoteCard && w.note.guid == id,
        );
        Finder text(String value) => find.text(value);
        Future<void> more() => tap(find.byIcon(Icons.more_vert));
        final b = card('guide-b');
        final a = card('guide-a');
        final pin = find.descendant(of: b, matching: find.byType(NotePin));
        final from = tester.getCenter(b);
        final dest = from + const Offset(-55, 80);
        await shot('1_1', find.byType(AddNoteButton));
        await shot(
          '2_1',
          b,
          extra: [Rect.fromCircle(center: dest, radius: 20)],
          arrow: (from, dest),
        );
        await shot('2_2', b);
        await shot(
          '3_1',
          pin,
          extra: [tester.getRect(a)],
          arrow: (tester.getCenter(pin), tester.getCenter(a)),
        );
        await shot('3_3', pin);
        await shot(
          '6_2',
          b,
          extra: [tester.getRect(text(lang == 'vi' ? 'Công việc' : 'Work'))],
          arrow: (
            from,
            tester.getCenter(text(lang == 'vi' ? 'Công việc' : 'Work')),
          ),
        );
        await shot('7_4', find.byType(BoardBar));
        await shot('9_1', find.byTooltip(l.search));
        await shot('5_1', find.byTooltip(l.drawOnWall));
        await tap(find.byType(AddNoteButton));
        await shot('1_2', find.byKey(const ValueKey('add-normal')));
        await shot('4_1', find.byKey(const ValueKey('add-checklist')));
        await tester.ensureVisible(text(l.memoryWall));
        await shot('8_3', text(l.memoryWall));
        close();
        await tester.pumpAndSettle();
        unawaited(
          showNoteDialog(
            ctx(),
            note: fixtures.first,
            isNew: false,
            existing: fixtures,
          ),
        );
        await shot('1_3', find.byTooltip(l.save));
        await shot('4_3', find.byTooltip(l.reminder));
        close();
        await tester.pumpAndSettle();
        unawaited(
          showNoteDialog(
            ctx(),
            note: fixtures.first.clone()..type = NoteType.audio,
            isNew: false,
            existing: fixtures,
          ),
        );
        await shot('4_2', find.byIcon(Icons.mic_rounded));
        close();
        await tester.pumpAndSettle();
        await tester.longPress(b);
        await tester.pumpAndSettle();
        await shot('4_4', text(l.lockInPlace));
        await shot('9_3', text(l.select));
        await shot('10_1', text(l.saveShort));
        close();
        await tester.pumpAndSettle();
        await shot(
          '2_2',
          find.byTooltip(l.resize).last,
          extra: [tester.getRect(find.byTooltip(l.rotate).last).inflate(5)],
          contextBounds: tester.getRect(b),
        );
        await more();
        await shot('2_3', text(l.arrange));
        await shot('6_3', text(l.trash));
        await shot('7_1', text(l.galleryTitle));
        await shot('8_2', text(l.pinPhotos));
        await shot('12_2', text(l.lightsOff));
        close();
        await tester.pumpAndSettle();
        await shot('6_1', find.byTooltip(l.newBoard));
        await tap(text(lang == 'vi' ? 'Ý tưởng' : 'Ideas'));
        await shot('7_2', text(l.clearSamples));
        await shot('7_3', text(l.changeTheme));
        close();
        await tester.pumpAndSettle();
        await tester.longPressAt(const Offset(210, 680));
        await tester.pumpAndSettle();
        await shot('8_1', text(l.photosHere));
        close();
        await tester.pumpAndSettle();
        ImageService.docsDirForTest = null;
        final photos = [
          for (final name in ['wall_wood', 'wall_brick', 'wall_cork'])
            File('assets/images/$name.jpg').absolute.path,
        ];
        await tester.runAsync(() async {
          for (final photo in photos) {
            await precacheImage(FileImage(File(photo)), ctx());
            await precacheImage(
              ResizeImage(FileImage(File(photo)), width: 120),
              ctx(),
            );
          }
        });
        unawaited(
          showMemoryWallSheet(
            ctx(),
            count: 3,
            photos: photos,
            onAddPhotos: (_) async => [],
          ),
        );
        final addPhoto = find.byTooltip(l.memoryAddPhotosHint(20));
        await tester.pumpAndSettle();
        final addRect = tester.getRect(addPhoto);
        await shot(
          '8_4',
          addPhoto,
          contextBounds: Rect.fromLTWH(20, addRect.top - 36, 390, 190),
        );
        close();
        await tester.pumpAndSettle();
        await tap(find.byTooltip(l.drawOnWall));
        await tester.dragFrom(const Offset(150, 500), const Offset(80, 90));
        await tester.pumpAndSettle();
        await shot(
          '5_2',
          find.byTooltip(l.eraser),
          focusOverride: const Rect.fromLTWH(120, 460, 140, 150),
        );
        await shot('5_3', find.byTooltip(l.eraser));
        await tap(find.byTooltip(l.done));
        await tap(find.byTooltip(l.layout));
        await shot('9_2', text(l.viewGrid));
        close();
        await tester.pumpAndSettle();
        await tap(find.byKey(const Key('header-share')));
        await shot('10_2', find.widgetWithText(FilledButton, l.share));
        close();
        await tester.pumpAndSettle();
        unawaited(showBoardPicker(ctx(), notes: notes, onDelete: (_) async {}));
        await shot('10_3', text(lang == 'vi' ? 'Công việc' : 'Work'));
        close();
        await tester.pumpAndSettle();
        unawaited(showAppSettings(ctx(), settings: settings, notes: notes));
        await shot('12_4', text(l.languageSection));
        await shot('12_3', text(l.widgetSection));
        await tester.ensureVisible(text(l.appLock));
        await shot('11_3', text(l.appLock));
        await tester.ensureVisible(text(l.exportData));
        await shot('11_1', text(l.exportData));
        await shot('11_2', text(l.importData));
        await tester.ensureVisible(text(l.syncTitle));
        await shot('11_sync', text(l.syncTitle));
        close();
        await tester.pumpAndSettle();
        await tap(find.byTooltip(l.customize));
        await shot('12_1', text(l.wallSection));
        close();
        await tester.pumpAndSettle();
        // Drag shows the real Undo banner; no fixture data leaves this test.
        await tester.drag(b, const Offset(-40, 30));
        await tester.pump();
        await shot('2_4', text(l.undo));
        // A real thread opens its actual style sheet on a tap.
        final linkMid = Offset.lerp(
          tester.getCenter(a),
          tester.getCenter(b),
          .5,
        )!;
        await tester.tapAt(linkMid);
        await tester.pumpAndSettle();
        await shot('3_2', find.byType(SwitchListTile));
        await tester.runAsync(() async {
          await File(
            'assets/manual/$lang/manifest.json',
          ).writeAsString(jsonEncode(manifest));
          final ratios = <String, double>{};
          for (final language in ['en', 'vi']) {
            final file = File('assets/manual/$language/manifest.json');
            if (!file.existsSync()) continue;
            final entries =
                jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
            for (final entry in entries.entries) {
              final crop =
                  (entry.value as Map<String, dynamic>)['crop'] as List;
              ratios['$language/${entry.key}'] =
                  (crop[2] as num) / (crop[3] as num);
            }
          }
          final keys = ratios.keys.toList()..sort();
          await File('lib/welcome/manual_image_ratios.dart').writeAsString(
            '// Generated by test/manual_assets_test.dart from real app UI.\n'
            'const manualImageRatios = <String, double>{\n'
            '${keys.map((key) => "  '$key': ${ratios[key]},").join('\n')}\n};\n',
          );
          await File('assets/manual/source.json').writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'sourceCommit': Process.runSync('git', [
                'rev-parse',
                'HEAD',
              ]).stdout.toString().trim(),
              'build':
                  '${RegExp(r"^version:\s*(\S+)", multiLine: true).firstMatch(File("pubspec.yaml").readAsStringSync())!.group(1)} / STICKY_SYNC=true',
              'method':
                  'Actual StickyWallApp widgets rendered by Flutter; cropped at measured target bounds; highlight drawn over original UI pixels. Fixture data only.',
              'files': manualSourceHashes(),
            }),
          );
        });
      },
    );
  }
}
