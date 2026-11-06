import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/screens/memory_wall_sheet.dart';
import 'package:sticky_wall/services/image_service.dart';
import 'package:sticky_wall/theme.dart';

/// The memory wall sheet shows which photos are chosen, lets one be taken
/// off, and never takes the same picture twice when more are added.
void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('memory_chosen_test');
    Directory('${temp.path}/note_images').createSync();
    ImageService.docsDirForTest = temp.path;
  });

  tearDown(() {
    ImageService.docsDirForTest = null;
    temp.deleteSync(recursive: true);
  });

  void photo(String name, int fill) => File(
    '${temp.path}/note_images/$name',
  ).writeAsBytesSync(List.filled(2000, fill));

  testWidgets('a photo picked again is left out; one can be removed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    photo('a.jpg', 1);
    photo('b.jpg', 2);
    photo('a-again.jpg', 1); // the same picture, copied in again
    photo('c.jpg', 3);
    MemoryWallChoice? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(fontChoices.first),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => picked = await showMemoryWallSheet(
                context,
                count: 2,
                photos: ['a.jpg', 'b.jpg'],
                onAddPhotos: (_) async => ['a-again.jpg', 'c.jpg'],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('2 photos', skipOffstage: false), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
    await tester.pumpAndSettle();
    expect(find.text('3 photos', skipOffstage: false), findsOneWidget);
    expect(
      find.text('1 photo was already chosen, so it was left out.'),
      findsOneWidget,
    );

    // The first thumbnail's remove badge.
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(find.text('2 photos', skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('Make the wall'));
    await tester.pumpAndSettle();
    expect(picked?.photos, ['b.jpg', 'c.jpg']);
  });
}
