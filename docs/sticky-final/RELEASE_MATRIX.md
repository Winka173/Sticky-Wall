# Release matrix (final commit on `main`)

- **Pass**: proven at that level.
- **Blocked**: needs a device, OS, account or store not available here.
- **—**: not applicable.
- **No device**: the release APK was built and launched on BlueStacks (Android 11), but nothing beyond launch and the first-run layout was run there. "Android device" means that BlueStacks instance.

| Feature | Unit / widget tests | Android device | iOS | Store / provider |
|---|---|---|---|---|
| Board Trash: delete, restore, expiry, purge, files kept, backup round-trip | Pass (`board_trash_test`, 11) | No device | Blocked | — |
| Retired drag tray and auto-trash; old settings harmless | Pass (`logic_test`, `editor_test`) | APK built and launched | Blocked | — |
| Backup limits and damaged-file count | Pass | No device | Blocked | — |
| Editor Save / Discard / Keep editing | Pass (`editor_test`) | No device | Blocked | — |
| Multi-photo share (≤ 20, limits, de-duplication) | Pass (`share_photos_test`) | **Blocked**: adb cannot send the multi-image share; try a manual share from the gallery app on BlueStacks | Blocked | — |
| Interactive guide (tap, drag, thread, Skip, Replay) | Pass (`guided_tour_test`) | No device | Blocked | — |
| First-run layout on wide screens | Pass (7 screen sizes) | **Pass**: BlueStacks 960×540 screenshot | Blocked | — |
| Template and theme catalog at 320 dp / 200 % text | Pass (`catalog_audit_test`) | No device | Blocked | — |
| Accessibility guidelines (labels, 48 dp) | Pass (`accessibility_test`) | TalkBack not run | Blocked | — |
| Memory Wall live preview | Pass (`memory_wall_test`) | No device | Blocked | — |
| Sync engine and service | Pass (`sync_test`, 12) | APK built and launched | Not offered | **Blocked**: OAuth client not set up; no real Drive run |
| Pro purchase / restore / refund | Pass (injected answers, earlier) | — | Blocked | **Blocked**: a license-tester run is still needed |
| Widgets, notifications, TalkBack | Earlier tests only | Not run | Blocked | — |

## Release blockers, in priority order

1. **Google Drive OAuth clients.** Both Android clients are needed: one for the upload key and one for the Play signing key. Then a two-phone sync test. Normal builds already hide sync; build with `STICKY_SYNC=true` once that test passes.
2. **Play Data safety review for opt-in sync.** Republish `PRIVACY.md`.
3. **Manual multi-photo share** from a real gallery app.
4. **License-tester purchase run:** buy, pending, refund.
5. **iOS:** everything needs a Mac.
