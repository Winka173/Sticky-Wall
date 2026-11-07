import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// UI files used to author the manual pictures. Normalize line endings so the
/// manifest is stable between Windows checkouts and CI.
Map<String, String> manualSourceHashes() {
  final files = <File>[
    File('lib/theme.dart'),
    File('lib/l10n/app_en.arb'),
    File('lib/l10n/app_vi.arb'),
    for (final dir in ['lib/screens', 'lib/widgets'])
      ...Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
  ]..sort((a, b) => a.path.compareTo(b.path));
  return {
    for (final file in files)
      file.path.replaceAll('\\', '/'): sha256
          .convert(
            utf8.encode(file.readAsStringSync().replaceAll('\r\n', '\n')),
          )
          .toString(),
  };
}
