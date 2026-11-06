import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/image_service.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';
import 'package:sticky_wall/widgets/stickers.dart';

void main() {
  testWidgets('mixed wall: 200 text, 30 stickers, 20 photos, 100 yarn links', (
    tester,
  ) async {
    ImageService.docsDirForTest = null;
    addTearDown(() => ImageService.docsDirForTest = null);
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final photo = File('assets/images/wall_wood.jpg').absolute.path;
    final art = stickers
        .where((s) => s.kind == StickerKind.image)
        .take(30)
        .toList();
    SharedPreferences.setMockInitialValues({});
    final storage = await NoteStorage.create();
    await storage.saveBoards([Board(id: 'default', name: 'Mixed wall')]);
    final notes = [
      for (var i = 0; i < 250; i++)
        Note(
          guid: 'mixed-$i',
          boardId: 'default',
          content: i < 200 ? 'Ghi chú $i' : '',
          createdAt: DateTime(2026).add(Duration(minutes: i)),
          type: i < 200
              ? NoteType.normal
              : i < 230
              ? NoteType.sticker
              : NoteType.photo,
          sticker: i >= 200 && i < 230 ? art[i - 200].id : '',
          imagePath: i >= 230 ? photo : '',
          x: (i * 37 % 100) / 100,
          y: (i * 53 % 100) / 100,
        ),
    ];
    await storage.saveNotes(notes);
    await storage.saveLinks([
      for (var i = 0; i < 100; i++) NoteLink('mixed-$i', 'mixed-${i + 1}'),
    ]);
    await storage.setViewMode(ViewMode.wall);
    final controller = NotesController(storage, ReminderService());
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    await tester.runAsync(() async {
      await precacheImage(
        FileImage(File(photo)),
        tester.element(find.byType(Scaffold)),
      );
    });
    final clock = Stopwatch()..start();
    await tester.pumpWidget(
      StickyWallApp(notes: controller, settings: SettingsController(storage)),
    );
    await tester.pumpAndSettle();
    final open = clock.elapsedMilliseconds;
    clock.reset();
    controller.search = 'ghi chu 19';
    await tester.pumpAndSettle();
    final search = clock.elapsedMilliseconds;
    expect(controller.visibleNotes, isNotEmpty);
    controller.search = '';
    controller.viewMode = ViewMode.grid;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(controller.boardNotes.length, 250);
    debugPrint(
      'MIXED PERF (test VM) open=${open}ms search=${search}ms; '
      '250 objects, 100 links. Not device FPS/RAM.',
    );
    expect(open, lessThan(20000));
  });
}
