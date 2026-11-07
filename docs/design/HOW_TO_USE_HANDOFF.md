# How to use — 1.5.0+11

2026-11-07. Base: `main` / `edaa981cc08985bd2db3050828dab6273e85661e`.
Fetched `origin/main` and verified identical HEAD, with zero commits ahead or
behind. Debug APK built with `--dart-define=STICKY_SYNC=true`.

The topic list still contains 12 topics and Replay onboarding. A topic now opens
in a draggable bottom sheet, with numbered instructions, short EN/VI copy, one
static picture per step, Previous/Next, Close and an always-available Done button.
The existing onboarding is unchanged. All reading remains passive.

The initial separate UI reconstruction was removed. Pictures are now generated
from the current app widgets: Add (including descriptions), editor, real note
menus, thread controls, board menus, Memory Wall with selected-photo thumbnails
and its current add-photo icon, export, Customize and Settings. The highlight
uses actual control bounds. Source hashes and image coverage are checked by a
normal regression test to catch stale pictures after UI changes.

The 84 PNGs add approximately 16 MB of source assets. The aspect-ratio table
reserves layout before images decode. Instruction text scales with system text
size; illustrative images are excluded from screen-reader semantics because the
corresponding numbered instruction provides the action. Missing picture coverage
is a failing test.

`settings_sheet.dart` now uses Flutter's target platform for widget availability,
allowing the real Android settings UI to be rendered in desktop Flutter tests.
Runtime platform behavior remains Android/iOS only, with web excluded.

Validation: 77 focused regression tests passed with sync enabled, including
existing onboarding, Settings, editor and accessibility tests. Asset generation
passed in both languages. Screenshot capture covers all steps in five layouts:
390dp EN, 320dp EN, 320dp VI at 200% text, 390dp VI Lights off, and 1280dp EN.
Scoped analysis is clean; debug APK built. Device captures and APK/source
provenance are in the review, separately labeled from Flutter test renders.

- [Current review](../../output/how_to_use/review.html)
- [Asset generation and provenance](../../assets/manual/README.md)
- [Source fingerprint](../../assets/manual/source.json)
- [Regression log](../../output/how_to_use_final_tests.log)
- [Analyze log](../../output/how_to_use_analyze.log)
- [Android build log](../../output/how_to_use_build.log)

No user data migration, entitlement changes or store upload. Commit and push
history are recorded in Git.
