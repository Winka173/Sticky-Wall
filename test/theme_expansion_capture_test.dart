// Actual production preview widgets, rendered for visual inspection.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/screens/gallery_screen.dart';
import 'package:sticky_wall/services/theme_packs.dart';
import 'package:sticky_wall/theme.dart';

import 'preview_fonts.dart';

void main() {
  testWidgets(
    'new theme preview captures in English and Vietnamese',
    skip: !const bool.fromEnvironment('THEME_CAPTURE'),
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 680);
      addTearDown(tester.view.reset);
      await loadPreviewFonts();
      for (final lang in ['vi', 'en']) {
        for (final id in [
          'sunny_kitchen',
          'lilac_desk',
          'garden_sketches',
          'berry_scrapbook',
          'night_observatory',
          'seaside_postcards',
        ]) {
          final pack = themePackById(id)!;
          final key = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: buildAppTheme(fontChoiceById(pack.font), pin: pack.pin),
              home: RepaintBoundary(
                key: key,
                child: Scaffold(
                  appBar: AppBar(title: Text(pack.name(lang))),
                  body: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ThemePreview(pack: pack),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(ThemePreview));
          await tester.runAsync(
            () => precacheImage(AssetImage(pack.wallStyle.asset), context),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$lang $id');
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File('output/theme_expansion/${lang}_$id.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    },
  );
}
