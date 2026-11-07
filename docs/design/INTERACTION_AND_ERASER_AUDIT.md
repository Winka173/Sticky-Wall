# Interaction latency and wall eraser — 2026-11-07

Implementation started from main `edaa981`, app 1.5.0+11. Final integration and
commit history are recorded in Git.
The existing How to use navigation position is unchanged, per the owner.

## Findings and changes

1. **300 ms gesture arbitration on wall notes.** WallView supplied both a
   single-tap editor callback and a double-tap camera callback. The double-tap
   recognizer also held the checklist's nested tap in the gesture arena.
   A regression probe reproduced **304 ms** for both actions. Single taps now
   act without that wait. With the owner's explicit choice, camera focus moved
   to **long press → Zoom to note**, retaining the existing zoom/reset behavior.
2. **Checkbox appearance lag.** The checked icon was scaled in over 160 ms.
   Its state/icon now changes immediately. Editor entry/exit uses 120/90 ms
   transitions, respecting reduced motion.
3. **Whole-wall work while drawing.** Every pointer movement called setState
   on WallView, reconstructing the notes and other wall children. A repaint
   notifier now updates only the ink's RepaintBoundary; the eraser cursor has
   its own small listenable subtree. A test sends 20 moves and verifies zero
   additional note constructions during the gesture.
4. **Controls could overlap on an empty board.** The Add label previously
   depended on a fixed 420dp threshold, ignoring actual text width and text
   scaling. It can cover the tool pill. The label now appears only when its
   measured width fits beside all four tools. Hit-tested flows pass at
   320, 430 and 600dp.

The root app already filters board font/pin notifications, the home-widget
service already skips identical payloads, and the editor has no awaited disk
operation before opening. These were checked rather than rewritten. Synchronous
JSON persistence is still present; this work does not claim unlimited board size
or eliminate every possible cold-frame spike.

## Partial wall erasing

The old eraser removed a whole stroke if it touched one of its sampled points.
The new eraser clips the polyline against a swept circle (a capsule between
pointer samples). Fast movements can cut a line even when neither event lands
on it. Untouched pieces retain color, opacity and width; the visible cursor
keeps a 28dp diameter when zooming.

Surviving wall-stroke fragments share their original placement anchor, stored
as an optional `anchor` field alongside the existing reference dimensions.
Existing strokes require no migration. Copy/JSON/backup/sync use DrawStroke's
existing serialization path. Tests verify alignment on different screen sizes,
legacy normalized strokes, repeated cuts, dots, sparse segments and loops.
One continuous erase makes one Undo step; misses make none. Undo restores the
original untouched stroke objects. The separate drawing-note canvas retains
its existing eraser behavior; this request concerns drawing on the wall.

## Verification

- **374 passed, 63 skipped** in the configured full Flutter suite with sync
  enabled. The focused eraser/gesture/editor set passed 66 tests.
- Scoped analysis: clean.
- Source-image generation passed in both languages; guide text now describes
  partial erasing and the menu-based zoom action.
- The full run exposed an older Memory Wall assertion that all paper corners
  must fit, conflicting with main's explicitly documented phone-viewport
  preview. Production Memory Wall code was preserved. The test now verifies the
  existing viewport mode and visibility of every photo's center, retaining its
  20-photo coverage.
- Actual Android profile/AOT run, **50 in-memory fixture notes**: 20 checkbox
  samples, median **18.003 ms**, p95 **37.761 ms**; 6 editor-open samples,
  median **18.673 ms**, p95 **26.864 ms**. These measure pointer-up to the first
  framework frame containing the changed state, not animation completion or
  display scanout. They are not a before/after hardware benchmark against the
  fake-clock regression probe.
- 321 sampled frame timings: build median 0.843 ms / p95 6.900 ms; raster
  median 3.020 ms / p95 16.380 ms. Maximum raster was 39.488 ms: occasional
  cold/emulator frame spikes remain. These results are specific to this AVD
  and fixture workload, not a guarantee for every device/data set.
- Native screenshots show a continuous line, the moving eraser circle, the
  resulting gap with both ends retained, and one Undo restoring the line.
- The profile entrypoint uses an in-memory preferences backend and is not the
  production entrypoint. Production APKs explicitly build `lib/main.dart` with
  `STICKY_SYNC=true`.

## Evidence

- [Review](../../output/interaction/review.html)
- [Native measurements](../../output/interaction/native_profile.json)
- [Native trace](../../output/interaction/native_profile.log)
- [Before: gesture probe](../../output/interaction_latency_before.log)
- [Focused checks](../../output/interaction_eraser_tests.log)
- [Full suite](../../output/interaction_full_tests.log)
- [Analysis](../../output/eraser_analyze.log)
- [Production release build](../../output/bluestacks_release_build.log)

No Free/Pro entitlement, account, or user-data migration changes.
