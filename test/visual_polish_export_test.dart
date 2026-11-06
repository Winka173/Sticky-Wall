import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/models/note.dart';
import 'package:sticky_wall/services/image_service.dart';
import 'package:sticky_wall/theme.dart';
import 'package:sticky_wall/widgets/board_poster.dart';
import 'package:sticky_wall/widgets/wall_view.dart';

import 'preview_fonts.dart';

class _ShareCapture extends ImageService {
  Uint8List? shared;
  @override
  Future<void> sharePng(Uint8List bytes, {String? subject}) async {
    shared = bytes;
  }
}

void main() {
  testWidgets('export shares the exact PNG rendered by its visible preview', (
    tester,
  ) async {
    await loadPreviewFonts();
    final service = _ShareCapture();
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    await tester.runAsync(
      () => precacheImage(
        AssetImage(walls.first.asset),
        tester.element(find.byType(Scaffold)),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(fontChoices.first),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BoardPosterPage(
          wall: walls.first,
          decor: false,
          soften: .2,
          notes: [
            Note(
              guid: 'export',
              content: 'Same paper, same picture',
              boardId: 'default',
              createdAt: DateTime(2026),
              rotation: .22,
              x: .9,
              y: .9,
              colorIndex: 0,
            ),
          ],
          links: const [],
          wallSize: const Size(360, 600),
          imageService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find
          .ancestor(
            of: find.byType(WallView),
            matching: find.byType(RepaintBoundary),
          )
          .first,
    );
    final expected = await tester.runAsync(
      () => ImageService.capture(boundary, pixelRatio: 3),
    );
    expect(expected, isNotNull);
    await tester.tap(find.text('Share'));
    await tester.pump();
    await tester.runAsync(() async {
      // toImage/PNG encode completes on the real engine, outside fake time.
      for (var i = 0; i < 100 && service.shared == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(service.shared, orderedEquals(expected!));
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final file = File('output/visual_polish/export_verified.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(service.shared!);
    });
  });
}
