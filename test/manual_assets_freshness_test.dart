import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_wall/l10n/app_localizations_en.dart';
import 'package:sticky_wall/l10n/app_localizations_vi.dart';
import 'package:sticky_wall/welcome/how_to_use.dart';
import 'package:sticky_wall/welcome/manual_image_ratios.dart';

import 'manual_asset_sources.dart';

void main() {
  test('manual screenshots match current production UI sources', () {
    final metadata =
        jsonDecode(File('assets/manual/source.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(
      metadata['files'],
      manualSourceHashes(),
      reason:
          'UI changed: regenerate with flutter test test/manual_assets_test.dart --dart-define=MANUAL_ASSETS=true --dart-define=STICKY_SYNC=true',
    );
  });

  test(
    'every English and Vietnamese step has a correctly sized real-UI image',
    () {
      for (final l in [AppLocalizationsEn(), AppLocalizationsVi()]) {
        final topics = manualTopics(l);
        expect(topics, hasLength(12));
        for (final (topicIndex, topic) in topics.indexed) {
          for (final step in topic.steps.indexed) {
            final key =
                '${l.localeName}/${manualAssetName(topicIndex, step.$1)}';
            expect(
              File('assets/manual/$key.png').existsSync(),
              isTrue,
              reason: key,
            );
            expect(manualImageRatios[key], greaterThan(0), reason: key);
          }
        }
        expect(
          File('assets/manual/${l.localeName}/11_sync.png').existsSync(),
          isTrue,
        );
      }
    },
  );
}
