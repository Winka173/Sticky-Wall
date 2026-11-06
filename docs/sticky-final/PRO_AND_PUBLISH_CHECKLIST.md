# Pro and publishing checklist

## Pro

- **Product:** `sticky_wall_pro`, a non-consumable with purchase option `buy`.
  - It is active in Play Console at 79,000 ₫.
  - Only the Vietnamese listing is filled in: add an English one.
- **Unchanged in this pass:**
  - The Free/Pro mapping.
  - Try-on.
  - Pro looks stay visible after a refund.
- **Sync is not gated behind Pro.**

## Before the next Play release

1. Bump `version:` in `pubspec.yaml`.
2. Add `android/fastlane/metadata/android/{en-US,vi}/changelogs/<code>.txt`.
3. Run `fastlane android build`, then `fastlane android closed` from `android/`.
4. Set up the Google Drive OAuth clients, or hide the sync row until they exist. See `SYNC_DESIGN_AND_LIMITATIONS.md`.
5. Republish `PRIVACY.md`: it has a new section on optional sync.
6. Recheck the Data safety answers now that opt-in sync exists.
7. New permission: none. `INTERNET` was already present through billing.

## Store text to update when sync ships

Say it once, plainly, in the store listing: *"Optional sync between your Android devices through your own Google Drive."*

Don't claim:

- encryption
- iPhone ↔ Android sync
- background sync while the app is closed

## External items only the owner can do

- The Google Cloud OAuth consent screen and the two Android OAuth clients.
- A license-tester purchase run.
- A Mac with Xcode for anything on iOS.
- The Play Console trader declaration (already started).
