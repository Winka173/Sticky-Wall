// Explicit screenshot generator. These are Flutter test renders, not device captures.
import 'dart:async';
import 'dart:io';
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
import 'package:sticky_wall/screens/gallery_screen.dart';
import 'package:sticky_wall/screens/memory_wall_sheet.dart';
import 'package:sticky_wall/screens/trash_screen.dart';
import 'package:sticky_wall/services/image_service.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/pro_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/services/template_library.dart';
import 'package:sticky_wall/theme.dart';
import 'package:sticky_wall/widgets/add_note_button.dart';
import 'package:sticky_wall/widgets/board_poster.dart';
import 'package:sticky_wall/widgets/note_dialog.dart';
import 'package:sticky_wall/widgets/settings_sheet.dart';

import 'preview_fonts.dart';

void main() {
  const capture = bool.fromEnvironment('POLISH_CAPTURE');
  const phase = String.fromEnvironment('POLISH_PHASE', defaultValue: 'after');
  for (final size in [
    const Size(390, 844),
    const Size(320, 700),
    const Size(900, 1000),
  ]) {
    testWidgets(
      'visual polish $phase ${size.width.toInt()}dp',
      skip: !capture,
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        await loadPreviewFonts();
        await tester.runAsync(TemplateLibrary.load);
        SharedPreferences.setMockInitialValues({});
        final storage = await NoteStorage.create();
        await storage.saveBoards([Board(id: 'default', name: 'Góc của mình')]);
        final notes = [
          Note(
            guid: 'a',
            content: 'Một ý tưởng nhỏ\ncho ngày mới',
            boardId: 'default',
            createdAt: DateTime(2026),
            x: .03,
            y: .08,
            colorIndex: 0,
          ),
          Note(
            guid: 'b',
            content: 'Hôm nay',
            boardId: 'default',
            createdAt: DateTime(2026),
            type: NoteType.checklist,
            checklist: [
              ChecklistItem(text: 'Đọc vài trang sách'),
              ChecklistItem(text: 'Tưới cây'),
            ],
            x: .95,
            y: .34,
            colorIndex: 2,
          ),
        ];
        await storage.saveNotes(notes);
        await storage.saveLinks([NoteLink('a', 'b')]);
        await storage.setLanguageCode('vi');
        await storage.setViewMode(ViewMode.wall);
        final controller = NotesController(storage, ReminderService());
        final settings = SettingsController(storage);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: StickyWallApp(
              notes: controller,
              settings: settings,
              pro: ProController(storage),
            ),
          ),
        );
        await tester.pumpAndSettle();
        BuildContext ctx() => tester.element(find.byType(Scaffold).first);
        await tester.runAsync(() async {
          for (final wall in walls) {
            await precacheImage(AssetImage(wall.asset), ctx());
          }
        });
        await tester.pumpAndSettle();
        Future<void> shot(String name) async {
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: name);
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            final file = File(
              'output/visual_polish/$phase/${size.width.toInt()}_$name.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes.buffer.asUint8List());
            image.dispose();
          });
        }

        void close() => Navigator.of(ctx()).pop();
        await shot('wall');
        await tester.tap(find.byType(AddNoteButton));
        await shot('add');
        close();
        await tester.pumpAndSettle();
        unawaited(
          showNoteDialog(
            ctx(),
            note: notes.first,
            isNew: false,
            existing: notes,
          ),
        );
        await shot('editor');
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await shot('editor_keyboard');
        tester.view.viewInsets = FakeViewPadding.zero;
        close();
        await tester.pumpAndSettle();
        for (final type in [
          NoteType.checklist,
          NoteType.drawing,
          NoteType.photo,
        ]) {
          unawaited(
            showNoteDialog(
              ctx(),
              note: notes.last.clone()..type = type,
              isNew: false,
              existing: notes,
            ),
          );
          await shot('editor_${type.name}');
          close();
          await tester.pumpAndSettle();
        }
        for (final mode in [ViewMode.grid, ViewMode.list]) {
          controller.viewMode = mode;
          await shot(mode.name);
        }
        unawaited(
          showSettingsSheet(ctx(), settings: settings, notes: controller),
        );
        await shot('settings');
        close();
        await tester.pumpAndSettle();
        unawaited(GalleryScreen.open(ctx(), notes: controller));
        await shot('gallery');
        close();
        await tester.pumpAndSettle();
        unawaited(GalleryScreen.open(ctx(), notes: controller, themes: true));
        await shot('themes');
        final words = AppLocalizations.of(ctx())!;
        final chipScroll = tester.state<ScrollableState>(
          find
              .ancestor(
                of: find.byTooltip(words.galleryFree),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        chipScroll.position.jumpTo(chipScroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(words.catSeasonal));
        await tester.pumpAndSettle();
        final trial = tester.widget<ThemeCatalogPreview>(
          find.byType(ThemeCatalogPreview).first,
        );
        await tester.tap(find.text(trial.pack.name('vi')));
        await shot('pro_preview');
        close();
        await tester.pumpAndSettle();
        close();
        await tester.pumpAndSettle();
        ImageService.docsDirForTest = null;
        // Material textures are selected-image fixtures, not customer photos.
        final photos = [
          for (final name in ['wall_wood', 'wall_brick', 'wall_cork'])
            File('assets/images/$name.jpg').absolute.path,
        ];
        await tester.runAsync(() async {
          for (final path in photos) {
            await precacheImage(FileImage(File(path)), ctx());
          }
        });
        unawaited(showMemoryWallSheet(ctx(), count: 3, photos: photos));
        await shot('memory');
        for (final label in [
          words.layoutPrints,
          words.layoutFilm,
          words.layoutTimeline,
          words.layoutHero,
        ]) {
          await tester.ensureVisible(find.byTooltip(label));
          await tester.tap(find.byTooltip(label));
          await shot('memory_${label.hashCode}');
        }
        close();
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(words.search));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'hom nay');
        await shot('search');
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pumpAndSettle();
        unawaited(
          Navigator.of(ctx()).push<void>(
            MaterialPageRoute(
              builder: (_) => BoardPosterPage(
                notes: controller.boardNotes,
                links: controller.linksOn('default'),
                wall: walls.first,
                decor: false,
                wallSize: const Size(390, 650),
                imageService: ImageService(),
              ),
            ),
          ),
        );
        await shot('export');
        close();
        await tester.pumpAndSettle();
        unawaited(
          Navigator.of(ctx()).push<void>(
            MaterialPageRoute(builder: (_) => TrashScreen(notes: controller)),
          ),
        );
        await shot('trash');
        close();
        await tester.pumpAndSettle();
        settings.setNightMode(NightMode.on);
        controller.viewMode = ViewMode.wall;
        await shot('night');
      },
    );
  }
}
