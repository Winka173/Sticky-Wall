import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/main.dart';
import 'package:sticky_wall/models/board.dart';
import 'package:sticky_wall/models/draw_stroke.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/models/view_mode.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/notes_controller.dart';
import 'package:sticky_wall/services/reminder_service.dart';
import 'package:sticky_wall/services/settings_controller.dart';

import 'preview_fonts.dart';

Future<void> _fonts() => loadPreviewFonts();

DateTime _t(int d) => DateTime(2026, 8, d, 9);

// A little scribbled smiley as normalized strokes.
List<DrawStroke> _smiley() => [
      DrawStroke(color: 0xFFC62828, width: 6, points: [
        for (var i = 0; i <= 20; i++)
          Offset(0.2 + 0.6 * (i / 20),
              0.5 + 0.25 * (1 - (2 * (i / 20) - 1) * (2 * (i / 20) - 1))),
      ]),
      DrawStroke(color: 0xFF1565C0, width: 6, points: [
        const Offset(0.35, 0.35),
        const Offset(0.35, 0.42),
      ]),
      DrawStroke(color: 0xFF1565C0, width: 6, points: [
        const Offset(0.65, 0.35),
        const Offset(0.65, 0.42),
      ]),
    ];

/// A little "snapshot" scene: a sky, a sun (or moon), and the ground or sea
/// below the horizon, optionally with sun glitter on the water.
typedef _Scene = ({
  String name,
  Color skyTop,
  Color skyBottom,
  Color sun,
  Offset sunAt,
  double sunSize,
  Color groundTop,
  Color groundBottom,
  bool glitter,
});

const _sunset = (
  name: 'sunset',
  skyTop: Color(0xFFFFD180),
  skyBottom: Color(0xFFEF6C00),
  sun: Color(0xFFFFF59D),
  sunAt: Offset(400, 230),
  sunSize: 52.0,
  groundTop: Color(0xFF1E88E5),
  groundBottom: Color(0xFF0D47A1),
  glitter: true,
);

const _dusk = (
  name: 'dusk',
  skyTop: Color(0xFF9575CD),
  skyBottom: Color(0xFF311B92),
  sun: Color(0xFFFFFDE7),
  sunAt: Offset(160, 110),
  sunSize: 30.0,
  groundTop: Color(0xFF283593),
  groundBottom: Color(0xFF0D1B4B),
  glitter: true,
);

const _meadow = (
  name: 'meadow',
  skyTop: Color(0xFFB3E5FC),
  skyBottom: Color(0xFF29B6F6),
  sun: Color(0xFFFFFFFF),
  sunAt: Offset(470, 90),
  sunSize: 38.0,
  groundTop: Color(0xFF66BB6A),
  groundBottom: Color(0xFF1B5E20),
  glitter: false,
);

/// Paints [scene] to a PNG in the temp folder and returns its path: a photo
/// print needs a real file. Must run inside [WidgetTester.runAsync].
Future<String> _makePhoto([_Scene scene = _sunset]) async {
  const w = 600.0, h = 400.0, horizon = 265.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(
    const Rect.fromLTWH(0, 0, w, horizon),
    Paint()
      ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, horizon),
          [scene.skyTop, scene.skyBottom]),
  );
  c.drawCircle(scene.sunAt, scene.sunSize, Paint()..color = scene.sun);
  c.drawRect(
    const Rect.fromLTWH(0, horizon, w, h - horizon),
    Paint()
      ..shader = ui.Gradient.linear(const Offset(0, horizon), const Offset(0, h),
          [scene.groundTop, scene.groundBottom]),
  );
  if (scene.glitter) {
    // Sun glitter on the water, spreading out below the sun.
    final glint = Paint()..color = scene.sun.withValues(alpha: 0.4);
    for (var y = horizon + 10; y < h; y += 22) {
      final spread = (y - horizon) * 0.6;
      c.drawRect(Rect.fromLTWH(scene.sunAt.dx - 30 - spread / 2, y, 60 + spread, 5), glint);
    }
  }
  final image = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${Directory.systemTemp.path}/sticky_wall_preview_${scene.name}.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  return file.path;
}

/// The three snapshots, decoded and ready (see [_pump]).
Future<List<String>> _makePhotos() async =>
    [for (final s in [_sunset, _dusk, _meadow]) await _makePhoto(s)];

Future<StickyWallApp> _app({
  required ViewMode mode,
  required List<Note> notes,
  List<NoteLink> links = const [],
  int wallIndex = 0,
  NightMode night = NightMode.off,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await NoteStorage.create();
  await storage
      .saveBoards([Board(id: 'default', name: '', wallIndex: wallIndex)]);
  await storage.saveNotes(notes);
  await storage.saveLinks(links);
  await storage.setViewMode(mode);
  await storage.setLanguageCode('vi');
  await storage.setNightMode(night);
  return StickyWallApp(
    settings: SettingsController(storage),
    notes: NotesController(storage, ReminderService()),
  );
}

Future<void> _pump(WidgetTester tester, Widget app,
    {String wallAsset = 'assets/images/wall_cork.jpg',
    List<String> photos = const []}) async {
  tester.view.physicalSize = const Size(1170, 2280);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // Photos go into the image cache *before* the first frame: an Image.file
  // that starts loading inside the test's fake-async zone never finishes,
  // and a later precache would only join that stuck load.
  await tester.runAsync(() async {
    for (final p in photos) {
      final done = Completer<void>();
      FileImage(File(p)).resolve(ImageConfiguration.empty).addListener(
            ImageStreamListener((_, _) => done.complete(),
                onError: (e, _) => done.completeError(e)),
          );
      await done.future;
    }
  });
  await tester.pumpWidget(app);
  await tester.runAsync(() async {
    final ctx = tester.element(find.byType(Scaffold).first);
    await precacheImage(AssetImage(wallAsset), ctx);
  });
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 130));
  }
}

List<Note> _wallNotes(List<String> photos) => [
      Note(guid: 'a', content: 'Nhớ tưới cây', boardId: 'default', createdAt: _t(1), colorIndex: 3, emoji: '🌱', x: 0.05, y: 0.02, scale: 1.15),
      Note(guid: 'b', content: '', boardId: 'default', createdAt: _t(2), type: NoteType.drawing, colorIndex: 0, strokes: _smiley(), x: 0.6, y: 0.04),
      Note(guid: 'c', content: 'Ghi chú to', boardId: 'default', createdAt: _t(3), pinned: true, colorIndex: 1, x: 0.06, y: 0.62, scale: 1.5),
      Note(guid: 'p', content: 'Biển hôm qua', boardId: 'default', createdAt: _t(4), type: NoteType.photo, images: photos, photoLayout: PhotoLayout.stack, x: 0.62, y: 0.3),
      Note(guid: 'd', content: 'nhỏ', boardId: 'default', createdAt: _t(5), colorIndex: 2, x: 0.45, y: 0.9, scale: 0.8),
    ];

void main() {
  testWidgets('mode wall features', skip: true, (tester) async {
    await _fonts();
    final photos = (await tester.runAsync(_makePhotos))!;
    final app = await _app(
      mode: ViewMode.wall,
      notes: _wallNotes(photos),
      // Red threads: the sketch to the big note, the print to the small one.
      links: const [NoteLink('b', 'c'), NoteLink('p', 'd')],
    );
    await _pump(tester, app, photos: photos);
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('mode_wall.png'));
  });

  testWidgets('night mode', skip: true, (tester) async {
    await _fonts();
    final photos = (await tester.runAsync(_makePhotos))!;
    final app = await _app(
      mode: ViewMode.wall,
      notes: _wallNotes(photos),
      links: const [NoteLink('a', 'd'), NoteLink('p', 'c')],
      wallIndex: 3, // plaster: the dimming is most visible on a light wall
      night: NightMode.on,
    );
    await _pump(tester, app,
        wallAsset: 'assets/images/wall_plaster.jpg', photos: photos);
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('night.png'));
  });

  testWidgets('trash', skip: true, (tester) async {
    await _fonts();
    final now = DateTime.now();
    final app = await _app(mode: ViewMode.grid, notes: [
      Note(guid: 'a', content: 'Nháp bài viết cũ', boardId: 'default', createdAt: _t(1), colorIndex: 2)
        ..deletedAt = now.subtract(const Duration(days: 2)),
      Note(guid: 'b', content: 'Đi chợ', boardId: 'default', createdAt: _t(2), type: NoteType.checklist, colorIndex: 0, checklist: [ChecklistItem(text: 'Sữa', done: true), ChecklistItem(text: 'Trứng', done: true)])
        ..deletedAt = now.subtract(const Duration(days: 12)),
      Note(guid: 'c', content: 'Link tham khảo', url: 'https://docs.flutter.dev', boardId: 'default', createdAt: _t(3), colorIndex: 3)
        ..deletedAt = now.subtract(const Duration(days: 28)),
      Note(guid: 'd', content: 'Còn giữ trên tường', boardId: 'default', createdAt: _t(4), colorIndex: 1),
    ]);
    await _pump(tester, app);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thùng rác (3)'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 130));
    }
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('trash.png'));
  });

  testWidgets('mode grid', skip: true, (tester) async {
    await _fonts();
    final photos = (await tester.runAsync(_makePhotos))!;
    final app = await _app(mode: ViewMode.grid, notes: [
      Note(guid: 'a', content: 'Đi chợ cuối tuần', boardId: 'default', createdAt: _t(1), type: NoteType.checklist, colorIndex: 0, checklist: [ChecklistItem(text: 'Sữa', done: true), ChecklistItem(text: 'Rau củ'), ChecklistItem(text: 'Trứng')]),
      Note(guid: 'b', content: 'Tài liệu Flutter', url: 'https://docs.flutter.dev', boardId: 'default', createdAt: _t(2), colorIndex: 3),
      Note(guid: 'c', content: 'Học tiếng Anh mỗi ngày,\n30 phút buổi sáng', boardId: 'default', createdAt: _t(3), colorIndex: 2, emoji: '📚'),
      Note(guid: 'd', content: 'Gọi điện cho mẹ', boardId: 'default', createdAt: _t(4), pinned: true, colorIndex: 1, reminderAt: DateTime(2026, 9, 10, 18)),
      Note(guid: 'e', content: 'Bản vẽ ý tưởng', boardId: 'default', createdAt: _t(5), type: NoteType.drawing, colorIndex: 4, strokes: _smiley()),
      Note(guid: 'p', content: 'Chuyến đi hè', boardId: 'default', createdAt: _t(6), type: NoteType.photo, images: [...photos, photos[0]], photoLayout: PhotoLayout.collage),
      Note(guid: 'q', content: '', boardId: 'default', createdAt: _t(7), type: NoteType.photo, images: [photos[2]], photoLayout: PhotoLayout.bare),
    ]);
    await _pump(tester, app, photos: photos);
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('mode_grid.png'));
  });

  testWidgets('mode list', skip: true, (tester) async {
    await _fonts();
    final photos = (await tester.runAsync(_makePhotos))!;
    final app = await _app(mode: ViewMode.list, notes: [
      Note(guid: 'a', content: 'Đi chợ cuối tuần', boardId: 'default', createdAt: _t(1), type: NoteType.checklist, colorIndex: 0, checklist: [ChecklistItem(text: 'Sữa', done: true), ChecklistItem(text: 'Rau củ')]),
      Note(guid: 'b', content: 'Tài liệu Flutter', url: 'https://docs.flutter.dev', boardId: 'default', createdAt: _t(2), colorIndex: 3),
      Note(guid: 'c', content: 'Học tiếng Anh mỗi ngày', boardId: 'default', createdAt: _t(3), colorIndex: 2, emoji: '📚'),
      Note(guid: 'd', content: 'Gọi điện cho mẹ', boardId: 'default', createdAt: _t(4), pinned: true, colorIndex: 1),
      Note(guid: 'e', content: 'Bản vẽ ý tưởng', boardId: 'default', createdAt: _t(5), type: NoteType.drawing, colorIndex: 4, strokes: _smiley()),
      Note(guid: 'p', content: 'Biển hôm qua', boardId: 'default', createdAt: _t(6), type: NoteType.photo, images: photos),
    ]);
    await _pump(tester, app, photos: photos);
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('mode_list.png'));
  });

  testWidgets('editor', skip: true, (tester) async {
    await _fonts();
    final app = await _app(mode: ViewMode.grid, notes: [
      Note(
        guid: 'a',
        content: 'Nhớ gọi điện hỏi thăm mẹ,\nhỏi sức khỏe của bà nữa',
        boardId: 'default',
        createdAt: _t(1),
        colorIndex: 1,
        emoji: '❤️',
        pinned: true,
        reminderAt: DateTime(2026, 9, 10, 18),
      ),
    ]);
    await _pump(tester, app);
    await tester.tap(find.textContaining('Nhớ gọi điện'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 130));
    }
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('editor.png'));
  });

  testWidgets('photo editor', skip: true, (tester) async {
    await _fonts();
    final photos = (await tester.runAsync(_makePhotos))!;
    final app = await _app(mode: ViewMode.grid, notes: [
      Note(
        guid: 'p',
        content: 'Chuyến đi hè',
        boardId: 'default',
        createdAt: _t(1),
        type: NoteType.photo,
        images: [...photos, photos[0]],
        photoLayout: PhotoLayout.collage,
        emoji: '✈️',
      ),
    ]);
    await _pump(tester, app, photos: photos);
    await tester.tap(find.textContaining('Chuyến đi'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 130));
    }
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('photo_editor.png'));
  });

  testWidgets('drawing editor', skip: true, (tester) async {
    await _fonts();
    final app = await _app(mode: ViewMode.grid, notes: [
      Note(
        guid: 'a',
        content: 'Bản vẽ ý tưởng',
        boardId: 'default',
        createdAt: _t(1),
        type: NoteType.drawing,
        colorIndex: 4,
        strokes: _smiley(),
        canvas: const DrawCanvas(
            color: 0xFFFFF3C4, pattern: CanvasPattern.grid),
      ),
    ]);
    await _pump(tester, app);
    await tester.tap(find.textContaining('Bản vẽ'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 130));
    }
    // Open the canvas paper panel so the tools are all on show.
    await tester.tap(find.byIcon(Icons.texture_outlined));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 130));
    }
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('drawing.png'));
  });

  testWidgets('settings sheet', skip: true, (tester) async {
    await _fonts();
    final photos = (await tester.runAsync(_makePhotos))!;
    final app = await _app(mode: ViewMode.wall, notes: _wallNotes(photos));
    await _pump(tester, app, photos: photos);
    await tester.tap(find.byIcon(Icons.palette_outlined).first);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 130));
    }
    await expectLater(
        find.byType(StickyWallApp), matchesGoldenFile('settings.png'));
  });
}
