# How to use: real UI pictures

These 84 cropped PNGs are generated from **the actual StickyWallApp widgets**,
with measured target bounds and a static spotlight. They are not illustrations
of a separately maintained copy of the UI. English and Vietnamese are bundled.
The content is synthetic fixture data; photo fixtures are repository textures.

Regenerate after UI changes:

```powershell
flutter test test/manual_assets_test.dart --dart-define=MANUAL_ASSETS=true --dart-define=STICKY_SYNC=true
dart format lib/welcome/manual_image_ratios.dart
flutter test test/manual_assets_freshness_test.dart --dart-define=STICKY_SYNC=true
```

The generator updates the PNGs, their aspect ratios, target/crop manifests and
`source.json`. A normal regression test verifies coverage of every translated
instruction and fingerprints the production UI sources, so UI changes require
the pictures to be regenerated. Reading the guide only loads bundled pictures;
it never creates notes, opens a picker, requests permissions or changes data.

These are Flutter-rendered source pictures. Screenshots of the running Android
app showing the resulting manual are kept separately under
`output/how_to_use/native/` and are labeled as device captures in the review.
