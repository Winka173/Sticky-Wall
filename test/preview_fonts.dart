// Font loading shared by the screenshot generators (preview_test.dart and
// modes_preview_test.dart). The test binding replaces every font with a
// block-glyph stand-in, so anything that should look real in a screenshot has
// to be loaded by hand: the app's typefaces from assets, and the Material
// icon font from the Flutter SDK's own cache.
import 'dart:io';

import 'package:flutter/services.dart';

/// Every typeface the app ships, keyed by the family name used in the theme.
const appFontFiles = {
  'PatrickHand': 'assets/fonts/PatrickHand-Regular.ttf',
  'Pacifico': 'assets/fonts/Pacifico-Regular.ttf',
  'Itim': 'assets/fonts/Itim-Regular.ttf',
  'DancingScript': 'assets/fonts/DancingScript.ttf',
  'BeVietnamPro': 'assets/fonts/BeVietnamPro-Regular.ttf',
  'Mali': 'assets/fonts/Mali-Regular.ttf',
  'Sriracha': 'assets/fonts/Sriracha-Regular.ttf',
  'Mynerve': 'assets/fonts/Mynerve-Regular.ttf',
  'FuzzyBubbles': 'assets/fonts/FuzzyBubbles-Regular.ttf',
  'AmaticSC': 'assets/fonts/AmaticSC-Regular.ttf',
  'Charm': 'assets/fonts/Charm-Regular.ttf',
  'IBMPlexMono': 'assets/fonts/IBMPlexMono-Regular.ttf',
};

/// Loads the app fonts plus Material icons, so screenshots show real glyphs.
Future<void> loadPreviewFonts() async {
  for (final e in appFontFiles.entries) {
    await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
  }
  final icons = _materialIconsFile();
  if (icons != null) {
    // Synchronous on purpose: real file I/O never completes under the test
    // binding's fake async clock.
    final bytes = icons.readAsBytesSync();
    await (FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(bytes))))
        .load();
  }
}

/// The icon font from the SDK that is running this test, when it is there.
File? _materialIconsFile() {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      // `flutter test` runs the Dart VM out of the SDK's cache.
      File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  for (final name in ['materialicons-regular.otf', 'MaterialIcons-Regular.otf']) {
    final f = File('$root/bin/cache/artifacts/material_fonts/$name');
    if (f.existsSync()) return f;
  }
  return null;
}
