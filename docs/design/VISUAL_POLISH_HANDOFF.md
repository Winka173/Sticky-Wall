# Sticky Wall visual polish — implementation handoff

Date: 2026-11-06. App version: **1.4.2+10**. Changes are in the working tree; no commit or store publication was performed.

Owner revision after the initial polish: restored the dark circular Save checkmark, direct icon ribbon for note types, and pencil on the yellow paper Add button. Fixed editor header, Add picker and the other improvements remain. Revision checks: analyze clean, **67 focused tests passed**, **3 capture cases passed** and current test-render images refreshed. The full-suite and Android results below describe the preceding polish verification, not an additional full/device run of this small revision.

## A. Implemented changes

Latest owner revision supersedes the selection trials below: icon + visible text, transparent backgrounds and no icon tiles; only the selected choice has a rounded outline and heavier text. No underline. Memory Wall now explicitly enables Android Photo Picker for batch selection, passes the 20-photo limit, and offers **Add photos** in the live preview. Adding photos keeps layout/frame/look/caption choices. Create is disabled while picking; cancellation and failed imports clean up copied files. The final confirmed photo list is used to create the wall, including subsequent batches.

Verification for this revision: **67 focused tests passed**, **3 capture cases passed** at 320/390/900dp; scoped analysis clean; Android debug APK built. The eight new tests cover Android picker configuration, batch order/import, limits and the final remaining slot, cancellation/error cleanup, and preview append/cancel/failure/cap behavior. Updated screenshots use repository texture fixtures and were visually inspected. Native picker behavior on a running Android device was not reverified in this revision (the dedicated AVD did not start); older device captures below remain historical.

Current owner-selected style supersedes the pastel and icon-only trials: choices show **icon + visible text, without backgrounds, icon tiles or borders**. Selection uses bold underlined text. Names/tooltips, Pro labels, semantics and touch targets remain. Language choices keep their names. Current focused suite: **106 passed**; screenshot generation: **3 passed**, refreshed at 320/390/900dp. Workspace-wide analyze at this point reported an unrelated unused import in concurrently added `test/marker_bar_test.dart`; the selection files are checked separately in `output/bare_choices_scoped_analyze.log`.

Subsequent choice-control refinement: `lib/widgets/paper_choice_chip.dart` supplies pastel icon/artwork backgrounds, softer outlines, selected fill and a separate trailing check (no check painted over the artwork). Used in Memory Wall layout/frame/caption options, catalog category filters and Settings/widget choices. Memory look thumbnails also have a softer selected border and labeled selection mark. Save/type/pencil controls requested by the owner remain intact. Verification for this refinement: analyze clean, **106 focused tests passed**, **3 capture cases passed**; updated 320/390/900dp renders inspected. [Choice comparison](../../output/choice_polish/comparison.jpg).

| Files | Result |
|---|---|
| `lib/theme.dart` | Central spacing, typography, icon roles, 48dp control metrics, motion and warm paper shadows. Sunny filled primary buttons, consistent outline/neutral actions and icon dimensions. Existing persisted palette order, wall/font IDs and per-board themes unchanged. |
| `lib/widgets/add_to_wall_sheet.dart` (new), `add_note_button.dart`, `lib/screens/home_screen.dart`, `home_screen_chrome.dart` | One yellow paper Add entrance for Wall/Grid/List; compact sheet with six labeled primary choices, Label/Sticker and Memory Wall. Text stays first. Both tap and long press open it; the competing “other kinds” pill is removed. Cards switch to one column on narrow screens or large text. |
| `lib/widgets/note_dialog.dart`, `note_dialog_pieces.dart` | Circular Save/Add checkmark and fixed adhesive header while the body scrolls above the keyboard. Direct icon ribbon for note types, with tooltips, selected state and horizontal scrolling on small screens. Photo/reminder/color stay nearby; emotion, pin and Delete use an options menu. Delete is separated from Save. Existing save/discard/validation/conversion/recording/media logic retained. |
| `lib/widgets/wall_background.dart`, `note_views.dart`, `photo_frames.dart` | Cork-only daylight softening and a gentler cork vignette. Shared warm paper shadows for cards/prints. These changes use the same renderer for wall and exports; no asset or card-coordinate migration. Other custom/pro wall materials remain intact. |
| `lib/screens/gallery_screen.dart` | Six curated entries grounded in existing categories, then the remaining catalog, without duplicate entries. Lazy grids, scalable caption space and accurate template-based theme thumbnails. Detail trials render detached copies of the user's real notes, media, yarn and marker strokes. Fixed Apply/Unlock footer. Rechecks entitlement/board state after purchase UI. Closed locked-board content is never rendered in the trial. |
| `lib/screens/memory_wall_sheet.dart` | Selected-image previews use the real wall/card/frame renderer, with native aspect ratios, timeline yarn and captions. Measured framing fits every print, including turned/overflowing photos, without changing the saved layout. Seven visual frame samples and explicit Pro labels. Pro frames/looks may be previewed; creation still requires current entitlement. |
| `lib/widgets/settings_sheet.dart`, `stickers.dart` | Readable, separated semantic Settings headings; tooltips naming sticker art. Existing settings and functional work are preserved. |
| `lib/l10n/app_en.arb`, `app_vi.arb`, generated localization files | Fourteen matching EN/VI strings for Add descriptions, editor options, featured content and honest temporary preview messaging. |

The change deliberately preserves the original tactile wall, board fonts, paper geometry, cork/other materials, pin artwork, drawings, yarn, photo frames and cassette notes. No new icon, font or image dependency was added to the app.

## B. Before/after evidence

- [Review gallery](../../output/visual_polish/review.html): before/after comparisons, current screenshots, source/device labels and evidence links.
- [Before/after contact sheet](../../output/visual_polish/before_after.jpg): Wall, Add, Editor, Editor with simulated keyboard inset and Settings.
- **30 baseline Flutter test renders**, ten surfaces at **320×700, 390×844 and 900×1000 logical px**, captured before UI changes. The baseline capture initially stopped at the async template-library loader; it is not presented as complete coverage of Gallery/Memory/Pro.
- **66 current Flutter test renders**, 22 surfaces at the same three sizes, 2× raster output. These cover Wall, Add, editor variants/keyboard inset, Grid, List, Settings, templates/themes, real-board Pro trial, all five Memory layouts, Search, Export, Trash and night mode. They are **test renders, not physical-device screenshots**.
- [Actual Android captures](../../output/visual_polish/device/): Android **15 / API 35**, dedicated `StickyWall_Ad_Review` AVD, **1080×1920 / density 420**. Save flows were confirmed in persisted preferences, not inferred from a screenshot.
- Memory preview fixture images are the repository's wood/brick/cork texture JPEGs selected as photos, not stock/customer photographs. Missing-image fixtures are used in the 20-print framing regression test.
- [Verified exported PNG](../../output/visual_polish/export_verified.png) contains the real rendered export, including a rotated note near the edge.

Screenshot generator: `test/visual_polish_capture_test.dart`:

```powershell
flutter test test/visual_polish_capture_test.dart --dart-define=POLISH_CAPTURE=true --dart-define=POLISH_PHASE=after
```

## C. Asset and icon audit

`python tool/audit_visual_assets.py` checked **all 197 shipped illustrated assets**: **161 stickers and 36 washi**, **45 free**, **2,112,658 bytes**. Dimensions, file lengths, SHA-256, transparent alpha, nonempty pixels, maximum edge (360px), Dart references and source/license metadata all pass. No byte-identical duplicates. Four light/dark contact sheets were visually inspected: no obvious opaque matte, unwanted background or major style break warranted changing shipped artwork.

**Zero images replaced. All IDs/paths/entitlements preserved.** This is not a legal originality certification or a guarantee against subtle near-duplicates/edge defects at every zoom level.

- [Machine-readable asset audit](../../output/visual_polish/audit/asset_audit.json)
- [Icon inventory](../../output/visual_polish/audit/icon_inventory.csv): all source occurrences with file, line, glyph/role and context. The app keeps its existing Material glyph dependency, with shared roles and outline conventions for the new/reworked controls; this is not a claim that every legacy glyph was replaced.
- [Artwork contact sheets](../../output/visual_polish/audit/)

## D. Tests and verification

Baseline before edits: `flutter analyze` clean; **298 tests passed, 53 skipped**. No pre-existing failure was observed.

Final checks:

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test --reporter expanded` | **314 passed, 56 skipped**; the skips include the three opt-in visual capture cases |
| Explicit screenshot generator | **3 passed**, 66 current PNGs; inspected representative small/standard/wide, editor, Pro and Memory renders |
| `flutter build apk --debug` | Successful Android debug build; installed on dedicated API 35 AVD |
| Actual Android Add → Text → Save | Verified, saved text found in app preferences |
| Actual Android Add → Checklist → Save | Verified, correct note type and text found in preferences |
| Actual Android Add → Photo → native picker → Save | Verified with the specifically named QA texture fixture, nonempty photo path persisted |
| Export preview → actual share payload | Exact PNG byte comparison passes at the default 3× export resolution; native share sheet replaced by a capture service in this test |
| Theme preview → cancel | Own note content/rotation shown; detached object identity and unchanged stored JSON verified, both with/without Pro |
| Theme preview → apply with Pro | Applies the previewed pack/color; content, position and rotation retained |
| Memory Pro preview | No paywall for choosing preview; Create/Unlock still requires entitlement |
| Locked-board trial | No own-note content or ThemeBoardPreview rendered; apply cannot dress the closed board |
| Responsive/accessibility | EN/VI Add sheet at 200% text, narrow 320px and wide 900px; existing target/label, editor and keyboard tests pass; complete template/theme layout audit at 320dp/200% EN+VI passes |
| Gestures/data regression | Existing move, rotate, resize, camera, threads, stacks, selection, Undo, backup/share/lock/Pro tests pass |
| Mixed scene | 200 text notes, 30 stickers, 20 photo notes, 100 yarn links; open/search/Grid pass |

Performance is **test VM timing**, not device FPS or RAM. In the final full-suite run, use the `PERF` and `MIXED PERF` lines in the log; concurrent capture/build activity affects these numbers. A separate mixed-scene run measured approximately **1.78s open / 0.47s search**. This is a regression sanity check with a generous 20s bound, not a consumer performance claim.

Logs: [analyze](../../output/polish_analyze.log), [full suite](../../output/polish_full_test.log), [captures](../../output/polish_capture.log), [Android build](../../output/polish_android_build.log), [mixed scene](../../output/polish_mixed_perf.log), [export](../../output/polish_export_checks.log), [native checks](../../output/visual_polish/device/interactive_checks.json).

Focused coverage is in `test/visual_polish_test.dart`, `visual_polish_mixed_perf_test.dart`, `visual_polish_export_test.dart`. Existing editor/accessibility/stability/Memory/widget tests were updated to follow the actual new Add/type/Delete paths and to distinguish frame samples from real preview prints. Assertions about persistence and functional outcomes were retained.

## E. Free/Pro and data safety

- Product remains **`sticky_wall_pro`**, a one-time non-consumable. No billing service, model, storage key, migration, media name, theme ID, palette index or cloud/sync engine was changed.
- Current catalog verified in test: **37 themes, 17 free; 3 free photo frames**. The original theme/sticker/asset catalogs and their entitlement flags are unchanged.
- Pro trial uses cloned notes and copied yarn styles. Cancel needs no storage rollback because it never writes. Apply still goes through the existing controller and its Undo. Entitlement is checked again at Apply, including after purchase UI.
- Existing Pro-styled content continues through the same renderer; choosing a new premium style remains gated. Existing tests for legacy rendering, purchase pending/offline/refund and restore UI pass; actual store transactions were not made.
- No user data was cleared. Native fixtures/preferences were written only after confirming the dedicated AVD name. Other connected Android devices were not used. Existing untracked ad/review artifacts were left alone.
- Functional workstreams were not rewritten. Owner-approved removal of the old delete tray/auto-trash controls remains with its assigned workstream; this pass does not promote those obsolete options. No sync navigation/status was removed.

## F. Remaining validation and limits

**P0 before a store release:** test real Play license purchase/pending/refund/restore; run a physical-device smoke pass including accessibility services, permission refusal, keyboard behavior and private-board Recents/widget surfaces. Existing Android build warnings about plugin compileSdk/Kotlin compatibility need the functional/build owner to review; the debug build succeeds.

**P1:** iOS compilation, Share Extension/WidgetKit/StoreKit and VoiceOver remain untested here. TalkBack was not exercised by a human; widget accessibility guidelines and actual Android semantics captures are supporting evidence, not a substitute. Profile device FPS/RAM with many distinct large photos; the mixed test reuses a texture fixture and does not simulate 20 independently decoded camera images.

**P2:** broader subjective review of all catalog covers on physical small phones and extreme text settings; selective refinement of any artwork found weak at high zoom. Existing template catalog/source and seasonal ordering were preserved, not redesigned or reclassified wholesale.

No production-ready/all-platform certification is claimed. The implemented UI and passing checks are concrete; the limits above remain explicit.
