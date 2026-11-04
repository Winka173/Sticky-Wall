// Contact sheets of every board template and theme pack, drawn by the app's
// own wall renderer, for reviewing the library at a glance. Not a regression
// test: remove `skip: true`, run
//   flutter test --update-goldens test/library_sheet_test.dart
// put it back, and save the PNGs from test/library/ as JPEG in docs/previews/.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/screens/gallery_screen.dart';
import 'package:sticky_wall/services/template_library.dart';
import 'package:sticky_wall/services/theme_packs.dart';
import 'package:sticky_wall/theme.dart';
import 'package:sticky_wall/widgets/pro_sheet.dart';

import 'preview_fonts.dart';

const _cols = 4;
const _rows = 3;
const _cell = Size(270, 500);

Future<void> _sheet(
  WidgetTester tester,
  String name,
  List<(Widget, String, bool)> cells,
) async {
  tester.view.physicalSize = Size(
    _cell.width * _cols,
    _cell.height * _rows,
  );
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('vi'),
      theme: buildAppTheme(fontChoices.first),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(
        color: AppColors.paper,
        child: Wrap(
          children: [
            for (final (preview, label, pro) in cells)
              SizedBox.fromSize(
                size: _cell,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: preview,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          if (pro) ...[
                            const SizedBox(width: 6),
                            const ProMark(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  // Wall textures decode outside the fake clock, before they are needed.
  await tester.runAsync(() async {
    final ctx = tester.element(find.byType(Material).first);
    for (final w in walls) {
      await precacheImage(AssetImage(w.asset), ctx);
    }
  });
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('library/$name.png'),
  );
}

void main() {
  setUpAll(loadPreviewFonts);

  final templates = TemplateLibrary.parse(
    File('assets/templates/templates.json').readAsStringSync(),
  );
  const perSheet = _cols * _rows;

  for (var page = 0; page * perSheet < templates.length; page++) {
    testWidgets('templates ${page + 1}', skip: true, (tester) async {
      final slice = templates.skip(page * perSheet).take(perSheet);
      await _sheet(tester, 'templates_${page + 1}', [
        for (final t in slice)
          (TemplatePreview(template: t), t.name.vi, false),
      ]);
    });
  }

  for (var page = 0; page * perSheet < themePacks.length; page++) {
    testWidgets('themes ${page + 1}', skip: true, (tester) async {
      final slice = themePacks.skip(page * perSheet).take(perSheet);
      await _sheet(tester, 'themes_${page + 1}', [
        for (final t in slice) (ThemePreview(pack: t), t.nameVi, t.pro),
      ]);
    });
  }
}
