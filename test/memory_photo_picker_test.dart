import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:sticky_wall/l10n/app_localizations.dart';
import 'package:sticky_wall/screens/memory_wall_sheet.dart';
import 'package:sticky_wall/services/image_service.dart';
import 'package:sticky_wall/theme.dart';

class _AndroidPicker extends ImagePickerAndroid {
  List<XFile> files = [];
  bool? usedPhotoPicker;
  int? requestedLimit;
  bool fail = false;

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    usedPhotoPicker = useAndroidPhotoPicker;
    requestedLimit = options.limit;
    if (fail) throw StateError('picker failed');
    return files;
  }

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => files.firstOrNull;
}

/// The small "add photos" button (its icon turns into a spinner while
/// the picker is open, so it is found by its tooltip).
final _addButton = find.byWidgetPredicate(
  (w) => w is IconButton && (w.tooltip?.contains('Add up to') ?? false),
);

void main() {
  group('Memory photo import', () {
    late Directory temp;
    late ImagePickerPlatform original;
    late _AndroidPicker picker;

    setUp(() {
      original = ImagePickerPlatform.instance;
      picker = _AndroidPicker();
      ImagePickerPlatform.instance = picker;
      temp = Directory.systemTemp.createTempSync('memory_picker_');
      ImageService.docsDirForTest = '${temp.path}/docs';
      picker.files = [
        for (var i = 0; i < 3; i++)
          XFile((File('${temp.path}/$i.jpg')..writeAsBytesSync([i])).path),
      ];
    });

    tearDown(() {
      ImagePickerPlatform.instance = original;
      ImageService.docsDirForTest = null;
      temp.deleteSync(recursive: true);
    });

    test(
      'uses Android multi-select and imports every photo in order',
      () async {
        final result = await ImageService().pickImages(limit: 20);
        expect(picker.usedPhotoPicker, isTrue);
        expect(picker.requestedLimit, 20);
        expect(picker.useAndroidPhotoPicker, isFalse);
        expect(result.toSet().length, 3);
        expect(
          [
            for (final name in result)
              File(ImageService.resolve(name)).readAsBytesSync(),
          ],
          [
            [0],
            [1],
            [2],
          ],
        );
      },
    );

    test(
      'caps providers that ignore the limit; final remaining slot works',
      () async {
        expect(await ImageService().pickImages(limit: 2), hasLength(2));
        expect(await ImageService().pickImages(limit: 1), hasLength(1));
      },
    );

    test('cancel and picker failure restore the platform setting', () async {
      picker.files = [];
      expect(await ImageService().pickImages(limit: 20), isEmpty);
      picker.fail = true;
      await expectLater(ImageService().pickImages(limit: 20), throwsStateError);
      expect(picker.useAndroidPhotoPicker, isFalse);
    });

    test('a partial failed import leaves no unused photo copies', () async {
      picker.files.add(XFile('${temp.path}/missing.jpg'));
      await expectLater(
        ImageService().pickImages(limit: 20),
        throwsA(isA<FileSystemException>()),
      );
      expect(Directory('${temp.path}/docs/note_images').listSync(), isEmpty);
    });
  });

  for (final scenario in ['append', 'cancel', 'failure', 'cap']) {
    testWidgets('memory preview add photos: $scenario', (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      MemoryWallChoice? result;
      final pending = Completer<List<String>>();
      int? remaining;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(fontChoices.first),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('open'),
                onPressed: () async => result = await showMemoryWallSheet(
                  context,
                  count: 1,
                  photos: ['first.jpg'],
                  onAddPhotos: (slots) {
                    remaining = slots;
                    return pending.future;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      // A spinner turns while the picker is open: one frame, not settle.
      await tester.pump();
      expect(remaining, 19);
      expect(tester.widget<IconButton>(_addButton).onPressed, isNull);
      expect(result, isNull);
      switch (scenario) {
        case 'append':
          pending.complete(['second.jpg', 'third.jpg']);
        case 'cancel':
          pending.complete([]);
        case 'failure':
          pending.completeError(StateError('picker failed'));
        case 'cap':
          pending.complete([for (var i = 0; i < 19; i++) 'extra$i.jpg']);
      }
      await tester.pumpAndSettle();
      if (scenario == 'failure') {
        expect(
          find.text(
            AppLocalizations.of(
              tester.element(find.text('Make the wall')),
            )!.photoPickFailed,
          ),
          findsOneWidget,
        );
      }
      if (scenario == 'cap') {
        expect(find.text('20 photos'), findsOneWidget);
        expect(tester.widget<IconButton>(_addButton).onPressed, isNull);
      }
      await tester.ensureVisible(find.text('Make the wall'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Make the wall'));
      await tester.pumpAndSettle();
      expect(
        result?.photos,
        scenario == 'append'
            ? ['first.jpg', 'second.jpg', 'third.jpg']
            : scenario == 'cap'
            ? ['first.jpg', for (var i = 0; i < 19; i++) 'extra$i.jpg']
            : ['first.jpg'],
      );
    });
  }
}
