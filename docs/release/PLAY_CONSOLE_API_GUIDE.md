# Releasing Sticky Wall (and any Winka Studio app) to Google Play

This is the one document to read before you build, publish or change the store
listing. It covers a fresh machine, the secrets, the one-command release, store
screenshots, a brand-new app on the same account, what still has to be done
by hand in the Play Console web UI, setting up sync across devices (Google
Drive) for Android and iOS (section 10), how every app handles in-app
purchases (section 11: trust Google Play's answer, no licensing key), going to
production (section 12), and where the legal links on the studio website
are used (section 13). Start with *How to help the owner*, right below: it says how to
answer when the owner asks for setup steps.

Sticky Wall (`com.apps.winka.stickywall`) is the working reference. Copy
`android/fastlane/` and `tool/play.py` from it for another app.

---

## How to help the owner with this guide (every repo, every app)

The owner clicks the consoles (Play Console, Google Cloud, Search Console,
App Store Connect); you guide. Whenever the owner asks how to set something
up, or sends a screenshot of a console page, answer **step by step, ready to
follow**, never with a summary:

1. **Name the page and give its direct link**, with the project or app filled
   in (`https://console.cloud.google.com/auth/branding?project=<id>`,
   `https://play.google.com/console`). Say the menu path too, because links
   move.
2. **Number every click in order**: which button, which tab, which option to
   choose, then *Save* / *Next* / *Create*. Group the steps under lettered
   headings (A. Create the project, B. Turn on the API, …) when there are
   many.
3. **Give the exact value for every field**, as a table: field → what to type
   (the app's real name, package, SHA-1, email, URLs). Say plainly which
   fields stay **empty** and why (for example: no logo, or Google must verify
   the app).
4. **Warn before anything that cannot be undone or that blocks**, at the
   step where it happens: deleting, publishing, "must be deleted before it
   can be created elsewhere", waiting times.
5. **End with how to check it worked**, and what the usual error looks like
   if it did not.
6. Read the screenshot: if the page shows something this guide does not
   expect (a disabled button, a missing field, a new layout), say what it
   means and fix the guide in the same turn.
7. **Write it back here.** A step you had to work out goes into this guide,
   in the same click-by-click form, so the next app and the next repo get it.

Reply in the owner's language (Vietnamese); this file stays in English.
Section 10.1 is the model to copy.

---

## 0. Publish a new version: the short path

When the owner says **"publish"**, do all of the following without further
questions. The release goes to **closed testing** (`alpha`) unless they name
another track.

1. **Pick the next version.**
   - Run `python tool/play.py codes` to get the highest versionCode Play has
     seen. The new code must be higher.
   - Bump `version: x.y.z+N` in `pubspec.yaml`. Patch for fixes, minor for
     features. `N` = that code + 1.
2. **Write the release notes.** They go in
   `android/fastlane/metadata/android/en-US/changelogs/N.txt` and
   `.../vi/changelogs/N.txt`.
   - Each is at most 500 characters, as `•` bullet lines.
   - Write for users, not developers.
   - Read `git log <last release commit>..HEAD` for the content.
     Release commits are named `x.y.z (N): release notes`.
3. **Check the app.**
   - Run `flutter analyze` (must be clean).
   - Run the full test suite: `flutter test --timeout 150s --dart-define=STICKY_SYNC=true`.
   - If `test/manual_assets_freshness_test.dart` fails, regenerate the
     How-to-use pictures (see `assets/manual/README.md`).
4. **Commit and push.**
   - Commit with the message `x.y.z (N): release notes`, then push `main`.
   - Another session may share the working tree: stage only your own files.
5. **Release.** From `android/`:
   ```sh
   fastlane android publish            # closed testing
   fastlane android publish track:internal
   ```
   The lane:
   - Runs `preflight`: `key.properties` must exist, both changelogs must
     exist and be ≤ 500 characters, and the versionCode must be above Play's
     highest.
   - Builds the signed, obfuscated bundle with `STICKY_SYNC=true`.
   - Uploads it as a draft, with the changelogs.
   - Rolls it out (`tool/play.py complete`).

   It ends with *"… is rolled out on alpha"*. Google then reviews the release,
   usually within minutes to a few hours, before testers get it.
6. **Report back:** the version, the track, the release notes, and the commit.

**Production** is never automated. The key cannot do it. The owner promotes a
tested release in Play Console. Personal accounts first need 12+ testers opted
in for 14 days in a row before production unlocks. Every step, the checklist
and later rollouts: **section 12**.

To try a build on a device or emulator without Play:

```sh
flutter build apk --release --obfuscate --split-debug-info=build/symbols-apk --dart-define=STICKY_SYNC=true
adb -s <device> install -r build/app/outputs/flutter-apk/app-release.apk
```

A signature mismatch on install means the device has a build signed with
another key. Uninstalling wipes the user's notes, so ask the owner first.

---

## 1. Accounts and IDs (already set up, shared by every app)

| Item | Value |
|---|---|
| Developer account | Winka Studio (personal account), id `5080364487976666246` |
| Google Cloud project | `play-publisher-513712`, with *Google Play Android Developer API* enabled |
| Service account | `play-publisher@play-publisher-513712.iam.gserviceaccount.com` |
| Its permissions | Account level, so they cover every app, including future ones. It **can**: view app info, manage the store listing, release to testing tracks, manage testers, manage in-app products. It **cannot**: release to production, see financial data, orders or users, or act as admin. |
| Sticky Wall package | `com.apps.winka.stickywall` |
| Pro product | one-time product `sticky_wall_pro` |
| Tracks | `internal`, `alpha` (= closed testing, where Sticky Wall's testers are), `beta` (= open testing), `production` (manual only) |

Nothing here has to be created again.

---

## 2. Secrets: outside the repo, never committed or printed

| Secret | Where it lives | Used by |
|---|---|---|
| Service-account key (JSON) | `~/.secrets/play-publisher.json` (`C:\Users\Winka\.secrets\play-publisher.json`), or the path in env `PLAY_KEY` | fastlane (`Appfile`), `tool/play.py` |
| Upload keystore | `C:\Users\Winka\sticky-wall-upload.jks`, alias `upload` | release signing |
| `android/key.properties` | in the repo folder but gitignored: `storeFile=…`, `storePassword=…`, `keyAlias=upload`, `keyPassword=…` | `android/app/build.gradle.kts` |

Without `key.properties`, release builds silently fall back to the debug key
and Play rejects them. `preflight` stops before that happens.

**On a new machine,** copy these three from the owner's backup to the same
paths. Never generate a new upload key for an existing app. If the upload key
is lost, the owner asks for an upload-key reset in Play Console → *App
integrity*.

**If the service-account key leaks:**
1. Delete it in Cloud Console → *IAM & Admin → Service Accounts →
   play-publisher → Keys*.
2. Create a new JSON key and save it to the path above.

---

## 3. A fresh machine, from zero (Windows)

| Tool | Version used | Notes |
|---|---|---|
| Flutter | 3.44.x stable | `flutter doctor` must show the Android toolchain with cmdline-tools and licences accepted (`flutter doctor --android-licenses`). Otherwise bundles fail to strip debug symbols. |
| JDK | 17 | Gradle targets Java 17 |
| Android SDK | via Android Studio | `android/local.properties` is written by Flutter |
| Ruby | 3.3 at `C:\Ruby33-x64\bin` | then `gem install fastlane` (2.241 in use) |
| Python | 3.x | `python -m pip install -r tool/requirements.txt`. Install it for the user, not isolated: `tool/play.py` must not be run with `python -I`. |
| Node | ≥ 20.9 | only for the store-screenshot skill (section 5) |

Shell setup (Git Bash):

```sh
export PATH="/c/Ruby33-x64/bin:$PATH"
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8          # fastlane needs UTF-8
export FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_HIDE_CHANGELOG=1 FASTLANE_OPT_OUT_USAGE=1
```

Check that everything works. These commands are read-only and safe to run any time:

```sh
flutter pub get && flutter analyze
cd android && fastlane android check        # key reaches the app; codes on closed testing
fastlane android preflight                  # is pubspec's version ready to ship?
cd .. && python tool/play.py check          # listings, images, tracks, testers, Pro product
python tool/play.py codes                   # highest versionCode Play has seen
```

### Sync builds (Google Drive)

Store builds are made with `--dart-define=STICKY_SYNC=true`. `publish` does
this by itself. Release 1.5.0 (11) and later were built this way. Turning sync
on in the app works only once Google Cloud is set up: see **section 10**
(Android and iOS).

---

## 4. Every tool, at a glance

From `android/` (`android/fastlane/Fastfile`):

| Lane | Writes to Play? | What it does |
|---|---|---|
| `check` | no | validates the key, lists closed-testing codes |
| `preflight` | no | keystore, changelogs (exist, ≤ 500), versionCode above Play's highest |
| `build` | no | `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols` (+ sync when `STICKY_SYNC=true`) |
| `closed` / `internal` | yes | uploads `build/app/outputs/bundle/release/app-release.aab` as a **draft** with the changelogs |
| `publish [track:alpha]` | yes | preflight → build (sync on) → upload → roll out. Testing tracks only. |
| `metadata` | yes | pushes `metadata/android/<lang>/{title,short_description,full_description,video}.txt` |
| `images` | yes | **replaces** store graphics with `metadata/android/<lang>/images/` |
| `pull` | local only | downloads the listing into `metadata/` (refuses if the folder exists) |

From the repo root (`tool/play.py`, needs the Python packages above):

| Command | Writes? | What it does |
|---|---|---|
| `python tool/play.py check [package]` | no | full report: languages, listing lengths, image counts, tracks, testers, bundles, products |
| `python tool/play.py codes` | no | highest versionCode ever uploaded |
| `python tool/play.py upload <aab> <track> [--name] [--notes]` | yes | upload as a draft, without fastlane |
| `python tool/play.py complete <track> <code>` | yes | rolls the draft with that code out to the whole track; it replaces older releases on the track |

Every write happens inside a Play "edit" that is committed only at the end. A
failed run leaves the console untouched.

Keep `build/symbols/` from each store build. It decodes the obfuscated crash
stack traces Play shows.

---

## 5. Store listing text and graphics

**Text** lives in `android/fastlane/metadata/android/{en-US,vi}/`.
- Files: `title.txt` (≤ 30), `short_description.txt` (≤ 80),
  `full_description.txt` (≤ 4000), `video.txt`.
- Edit them, then run `fastlane android metadata`.
- `.gitattributes` keeps them LF. Windows line endings would show up inside
  Play's text.
- Keep the listing honest. It must not claim features the build does not have.

**Graphics Play needs:**
- icon 512×512, 32-bit PNG (`store/icon_512.png`);
- feature graphic 1024×500 (`store/feature_graphic_1024x500.png`);
- 2–8 phone screenshots, 9:16, each side ≥ 1080 px to qualify for promotion
  (current set: `store/screenshots/01…08`, 1080×1920);
- optional 7" / 10" tablet screenshots.

They are uploaded from `metadata/android/<lang>/images/`. That folder is
gitignored, so it is a staging copy:
- `icon.png` and `featureGraphic.png` go directly in it;
- screenshots go in `phoneScreenshots/1.png`, `2.png`, …;
- tablet screenshots go in `sevenInchScreenshots/` and `tenInchScreenshots/`.

Fill it from `store/` (or from the screenshot studio's export), then run
`fastlane android images`. It replaces every image of each type it finds.

### Raw app captures

The raw captures are real-app goldens, made by the tests (see CLAUDE.md →
"Generated assets"):
1. Flip `skip: true` → `false` in `test/preview_test.dart` /
   `test/modes_preview_test.dart`.
2. Run `flutter test --update-goldens <file>`.
3. Flip `skip` back, and move the PNGs from `test/` to `screenshots/`.

Captures from the emulator work too:

```sh
adb -s <device> exec-out screencap -p > shot.png
```

### Marketing screenshots: the `app-store-screenshots` skill

The skill
[ParthJadhav/app-store-screenshots](https://skills.sh/ParthJadhav/app-store-screenshots)
turns raw captures into store **advertisements**: a headline per slide,
device frames, and bulk export at every Google Play and App Store size,
including the 1024×500 feature graphic.

- It is pinned in `skills-lock.json`. The skill itself (`.agents/`, plus the
  `.claude/skills` link) is gitignored.
- Restore it on a new machine with `npx skills experimental_install`. A fresh
  install is `npx skills add ParthJadhav/app-store-screenshots`.
- Agents (Claude Code, Codex, Cursor, …) pick it up when asked for store
  screenshots.

How to use it for Sticky Wall:

1. **Raw captures.** Use `store/screenshots/*.png`, or regenerate them as
   above. Capture each locale (`en`, `vi`) with the app's language set to
   match.
2. **Scaffold the editor outside the Flutter app.** It is a Next.js project
   and must never land in the repo root next to `pubspec.yaml`. Use a
   sibling folder:
   ```sh
   mkdir ../sticky-wall-store-studio && cd ../sticky-wall-store-studio
   cp -R ../Sticky-Wall/.agents/skills/app-store-screenshots/template/. .
   npm install && npm run dev        # bun / pnpm also work
   ```
3. **Feed it the captures.**
   - Captures go to `public/screenshots/android/phone/<locale>/01.png …`.
     The iPhone deck uses `public/screenshots/apple/iphone/<locale>/…`.
   - `store/icon_512.png` goes to `public/app-icon.png`.
   - The deck is saved in that folder's `app-store-screenshots.json`.
4. **Design the deck.**
   - Brand: warm cork and paper.
   - Style: closest to *Paper Sticker Skeuomorphic* (`style-prompts/03-…`).
   - Headlines sell an outcome. Example: "Your whole week on one wall", not
     "Wall view".
   - Google Play allows 8 slides; the App Store allows 10.
5. **Export, then publish.**
   - Copy the Android exports into
     `android/fastlane/metadata/android/<lang>/images/phoneScreenshots/`, and
     the 1024×500 banner as `featureGraphic.png`.
   - Copy the finished PNGs back to `store/screenshots/` so the repo keeps
     them.
   - Ask the owner before running `fastlane android images`: it replaces the
     live listing's pictures.
   - The App Store exports are for the iOS listing in App Store Connect,
     which is uploaded by hand.

---

## 6. A brand-new app on the same account

1. **Play Console → Create app.**
   - Use default language **English (United States)**.
   - Choose app or game, and free or paid.
   - Accept the declarations.
2. **In the repo:**
   1. Fix the `applicationId`. It can never change after the first upload.
   2. Create an upload keystore, kept outside the repo:
      ```powershell
      keytool -genkey -v -keystore $env:USERPROFILE\<app>-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
      ```
   3. Add a gitignored `android/key.properties` and wire it into
      `signingConfigs.release`. Copy that part from Sticky Wall's
      `build.gradle.kts`.
   4. Set the version as `x.y.z+versionCode` in `pubspec.yaml`.
3. **Build** with `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`.
4. **Upload this first `.aab` by hand.**
   - Play Console → *Test and release → Internal testing → Create release*.
   - Accept Play App Signing.
   - Saving as a draft is enough. Until one build exists, the API answers
     *"Package not found"*.
5. **Copy fastlane and the tool.**
   - Copy `android/fastlane/{Appfile,Fastfile}` and set `package_name` in
     `Appfile`.
   - Copy `tool/play.py` and `tool/requirements.txt`, and set
     `DEFAULT_PACKAGE`.
   - Add to `.gitignore`: `android/fastlane/metadata/android/*/images/`,
     `android/fastlane/report.xml`, `android/fastlane/README.md`.
   - Add to `.gitattributes`: `android/fastlane/metadata/** text eol=lf`.
6. **Check:** run `fastlane android check`. It should end with *"fastlane.tools
   finished successfully"*.
7. **Listing:** write the text files, run `fastlane android metadata`, stage
   the graphics, then run `fastlane android images`.
8. **The first review.** Until the app has passed its first review, Play
   accepts only drafts (*"Only releases with status draft may be created on
   draft app"*). Upload with `closed` or `internal`, then send the release for
   review in the web UI *(Publishing overview → Send changes for review)*.
   After that, `publish` rolls out by itself.

---

## 7. What the API cannot do (Play Console web UI, owner only)

- Create the app, and upload its very first bundle.
- **App content forms:**
  - privacy policy URL;
  - app access;
  - ads;
  - content rating (IARC);
  - target audience;
  - data safety;
  - advertising ID;
  - financial features;
  - government or health declarations.

  Sticky Wall's answers, with the reasons, are in
  `docs/release/PLAY_LISTING_1_4_1.md` (section 4) and README → *Releasing
  to Google Play*.
- **Store settings:** category, tags, contact details, external marketing.
- **Money:** merchant profile, prices, promo codes, license testers. In-app
  products can be created only after a bundle with the billing permission
  is uploaded. The app's code follows section 11; the licensing key on the
  *Monetization setup* page is not used.
- **Testers:** the closed-testing tester list or Google Group, and the
  opt-in link.
- **Production:** releasing to production, and applying for production
  access (section 12).

---

## 8. When something fails

| Message | Cause | Fix |
|---|---|---|
| `versionCode N is not above M` (preflight) | That code was already uploaded | Bump `+N` in `pubspec.yaml` to M + 1 |
| `Missing release notes …/changelogs/N.txt` | No notes for this code | Write both `en-US` and `vi` |
| `key.properties is missing` | No upload key on this machine | Copy the secrets (section 2) |
| `The caller does not have permission` | Service account not invited, or permissions still propagating | Play Console → *Users and permissions*; wait up to a few hours |
| `Package not found` | No build was ever uploaded for this app | Upload the first bundle by hand |
| `APK specifies a version code that has already been used` | The code exists on some track, even a discarded draft | Bump the code and rebuild |
| `Only releases with status draft may be created on draft app` | The app has never been reviewed | See section 6, step 8 |
| `No module named googleapiclient` | Python packages missing, or run with `python -I` | `python -m pip install -r tool/requirements.txt`; run without `-I` |
| fastlane `invalid byte sequence` / encoding errors | Shell not in UTF-8 | export `LC_ALL`/`LANG` as in section 3 |
| "failed to strip debug symbols" at the end of a build | Android cmdline-tools or licences missing | `flutter doctor`, then fix and rebuild |
| `download_from_play_store` errors at the end | It errors after the images, but the text is already saved | Check `metadata/android/<lang>/*.txt` |

---

## 9. Rules

- The key is the account. Read it only from `PLAY_KEY` or `~/.secrets/`.
  Never commit, print, paste or upload it, or the keystore and its passwords.
- Read-only commands (`check`, `preflight`, `codes`, `play.py check`) can run
  any time.
- Writes to Play need the owner's go-ahead:
  - "publish" covers a full release to testing (section 0);
  - listing text, graphics and products need their own ask.
- Production stays manual. The key deliberately cannot do it.
- Never delete or "clean up" releases, testers or products through the API.
- In-app purchases trust Google Play's answer (section 11). No licensing key,
  no on-device signature check, and buying is never disabled for a missing key.

---

## 10. Sync across devices (Google Drive): Android and iOS

Sticky Wall syncs through the **hidden app folder of the user's own Google
Drive** (`appDataFolder`, scope `drive.appdata` only). There is no Sticky Wall
server. How the merge works: `docs/sticky-final/SYNC_DESIGN_AND_LIMITATIONS.md`.

| | Android | iOS |
|---|---|---|
| In the code | Yes: `lib/services/sync/`, switched on in `lib/main.dart` when `Platform.isAndroid` and `STICKY_SYNC=true` | **No.** The sync row is not shown on iPhone |
| Google Cloud | Two Android OAuth clients (10.1) | One iOS OAuth client (10.2) |
| Verified on real Drive | Only once the clients exist; then run the test list in 10.3 | Never |

The repo cannot tell whether the Google Cloud part is done: open the project's
*Credentials* page and look. Nothing here is a secret: OAuth client ids and
certificate fingerprints are public, so they may go in docs and `Info.plist`.

### 10.1 Android, once per app (owner, Google Cloud console)

**One Google Cloud project per app**, shared by that app's platforms.
- A project has exactly one consent screen (one app name), and Drive's hidden
  app folder belongs to the **project**. Two apps in one project would share
  one folder and one name; Android and iPhone clients of the same app must be
  in the same project, or they never see each other's data.
- `play-publisher-513712` holds the Play service account only. Never put an
  app's OAuth clients there.
- An account can create a limited number of projects (about a dozen by
  default); ask Google for more from the quota page when needed.
- A package + SHA-1 pair can belong to **one OAuth client in all of Google
  Cloud**. To move an app to another project, delete its clients in the old
  project first (step D), then create them in the new one.
- Nothing goes into the Android project: no `google-services.json`, no client
  id in code. Google matches the package name + signing certificate. Moving
  projects needs no app change; sync data saved under the old project is not
  seen by the new one.

Click by click. Sticky Wall's values are shown; for another app use its name,
package and SHA-1s. In every URL below, replace `PROJECT` with the project id.

**A. Create the project**
1. https://console.cloud.google.com/projectcreate
   - *Project name:* the app (`Sticky Wall`). Note the **project ID** under it
     (for example `sticky-wall-123456`); you can edit it before creating.
   - *Location / Organization:* *No organization*. → **Create**.
2. Make sure the project picker at the top shows the new project before going
   on. Every step below happens inside it.

**B. Turn on the Drive API**
1. https://console.cloud.google.com/apis/library/drive.googleapis.com?project=PROJECT
   → **Enable**. That is the only API needed. No billing account is needed.

**C. Consent screen (Google Auth Platform)**
1. https://console.cloud.google.com/auth/overview?project=PROJECT → **Get
   started**. The wizard asks:
   1. *App information:* app name **Sticky Wall**; user support email
      `apps.winka.studio@gmail.com`. → Next.
   2. *Audience:* **External**. → Next.
   3. *Contact information:* `apps.winka.studio@gmail.com`. → Next.
   4. *Finish:* accept the Google API Services User Data Policy. → Continue →
      **Create**.
2. *Branding* (https://console.cloud.google.com/auth/branding?project=PROJECT):
   - **Leave the logo empty.** A logo makes Google verify the app before it
     can be published.
   - *App domain* and *Authorized domains* are **required before Audience
     lets you publish** ("complete your configuration on the Branding page").
     Every link must be on an authorized domain. All apps use the studio
     website `winka.top` (section 13 has every app's addresses):

     | Field | Sticky Wall |
     |---|---|
     | Application home page | `https://winka.top/en/apps/sticky-wall/` |
     | Application privacy policy link | `https://winka.top/en/apps/sticky-wall/privacy/` |
     | Application terms of service link | `https://winka.top/en/apps/sticky-wall/terms/` |
     | Authorized domains | `winka.top` (remove `github.com` once nothing uses it) |

     - Verify `winka.top` once in Google Search Console (a *Domain* property,
       DNS TXT record at the domain registrar) with the same Google account
       that owns the Cloud projects; then every app's project can use it.
       Before that, Google accepts it while it asks for no verification (no
       logo, only `drive.appdata`), but could not verify the app if it ever
       asked.
   - *Developer contact:* `apps.winka.studio@gmail.com`. → **Save**.
3. *Data Access* (https://console.cloud.google.com/auth/scopes?project=PROJECT):
   - **Add or remove scopes** → in the filter type `drive.appdata` → tick
     `.../auth/drive.appdata` (*See, create, and delete its own configuration
     data in your Google Drive*) → **Update**.
   - It lands under *Your non-sensitive scopes*: no security assessment.
     → **Save**.
4. *Audience* (https://console.cloud.google.com/auth/audience?project=PROJECT):
   - *Publishing status* → **Publish app** → **Confirm**. Status becomes
     *In production*.
   - Why: in *Testing*, only individually listed test users can sign in (up
     to 100), and **Google Groups are not accepted there**, so the Play
     testers' group would be shut out. Publishing is independent of Play: an
     app on closed testing can use a consent screen in production.

**D. Moving an app from another project: delete its old clients first**
1. Open the old project's clients (for example
   https://console.cloud.google.com/auth/clients?project=play-publisher-513712).
2. Open each of the app's clients and **copy its SHA-1** before deleting it.
3. Tick the app's clients → **Delete**. Only this app's clients: other apps'
   clients stay until their own move.

**E. Create the Android OAuth clients**
1. https://console.cloud.google.com/auth/clients?project=PROJECT → **Create
   client** → *Application type:* **Android**. Create these:

   | Name | Package name | SHA-1 certificate fingerprint |
   |---|---|---|
   | `Sticky Wall (Play signing)`: anything installed from Play, testers included | `com.apps.winka.stickywall` | Play Console → the app → *Test and release → Setup → App integrity → App signing* → *App signing key certificate* → **SHA-1** |
   | `Sticky Wall (upload key)`: sideloaded and locally built release APKs | `com.apps.winka.stickywall` | `D3:3A:8D:B4:1C:9E:53:41:9E:0B:A7:98:97:73:4D:75:60:A7:44:F2` (the *Upload key certificate* on the same Play page) |
   | `Sticky Wall (debug)`: optional, `flutter run` builds | `com.apps.winka.stickywall` | `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` |

   - Leave *Enable custom URI scheme* off. → **Create**. Nothing has to be
     downloaded or copied into the app.
   - If it fails with *package name and fingerprint already in use*, the pair
     is still in another project (step D); wait a few minutes and retry.
2. To read the upload SHA-1 from a release APK built on this machine, without
   the keystore password:
   `apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk`
   (`apksigner` is in `Sdk/build-tools/<version>/`). `keytool -printcert
   -jarfile` prints nothing for these APKs (they have no v1 signature).

**F. Check**
1. Wait a few minutes (sometimes up to an hour) for the clients to reach
   Google's servers.
2. Install the app from the closed-testing track (Play-signed) → *Customize
   → Sync across devices* → turn on → choose the account → **Allow**. The
   status should become *Synced …*. Then run the list in 10.3.
3. Failures: 10.4.

### 10.2 iOS (not built yet): what turning it on takes

Needs a Mac with Xcode for building and testing. Steps, in order:

1. **Google Cloud**, same project as 10.1: *Create OAuth client ID → iOS*,
   bundle ID **`com.winka.stickyWall`** (from `ios/Runner.xcodeproj`), Team ID
   from the Apple developer account. Note the **client ID**
   (`<number>-<id>.apps.googleusercontent.com`) and the **iOS URL scheme**
   (the reversed id, `com.googleusercontent.apps.<number>-<id>`).
2. **`ios/Runner/Info.plist`**: add
   ```xml
   <key>GIDClientID</key>
   <string>NUMBER-ID.apps.googleusercontent.com</string>
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key><string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array><string>com.googleusercontent.apps.NUMBER-ID</string></array>
     </dict>
   </array>
   ```
   (If `CFBundleURLTypes` already exists, add the `dict` to it.)
3. **Code** (one PR, with tests):
   - `lib/main.dart`: the sync gate `Platform.isAndroid && _syncBuild` becomes
     `(Platform.isAndroid || Platform.isIOS) && _syncBuild`.
   - On a device, check that turning sync on shows Google's sign-in sheet. If
     `authorizeScopes` fails on iOS with no signed-in user, call
     `GoogleSignIn.instance.authenticate(scopeHint: [DriveSyncBackend.scope])`
     first in `DriveSyncBackend.authorize`.
   - Strings, EN and VI (`lib/l10n/app_*.arb`, then `flutter gen-l10n`):
     `syncExplain` ("every Android device") and `syncPrivacy` ("iPhone and
     Android do not sync with each other") must say the new truth: with one
     Cloud project, **iPhone and Android sync with each other**.
   - `PRIVACY.md` ("Optional sync across devices (Android)") and
     `docs/sticky-final/SYNC_DESIGN_AND_LIMITATIONS.md` (Platforms, Not done).
   - Regenerate the manual pictures if the guide changes (see `CLAUDE.md`).
4. **App Store Connect → App Privacy**: sync sends data only to the user's own
   Drive at their request, nothing to the developer. Declare it the way the
   Play Data safety form does.
5. Build: `flutter build ipa --release --dart-define=STICKY_SYNC=true`, then
   TestFlight.

Why Google Drive and not iCloud on iPhone: one store of data for both
platforms. iCloud would need its own backend, an iCloud entitlement, and would
never reach Android.

### 10.3 Testing on real Drive (both platforms)

1. Install the store build (closed testing / TestFlight) on two devices signed
   in to the same Google account, which is a consent-screen test user.
2. *Customize → Sync across devices* → turn on → allow.
3. Run: edits on each device; one device offline while the other edits; delete
   then restore a board; photos and voice notes; a locked board with and
   without *Include locked boards*; turn sync off; revoke access in the Google
   account (*Security → Third-party connections*); for iOS, one iPhone and one
   Android phone.
4. Write the result in the Verification table of
   `docs/sticky-final/SYNC_DESIGN_AND_LIMITATIONS.md`.

### 10.4 When sync sign-in fails

| What you see | Cause | Fix |
|---|---|---|
| Sync shows *Allow access again* right after allowing; logcat has `DEVELOPER_ERROR` / status 10 | No Android client matches this package + SHA-1 | Add the client for the key that signed this install (Play installs: app-signing key; local release: upload key) |
| `access_denied` / "app has not completed verification" | Account isn't a test user while the consent screen is in Testing | Add the account as a test user, or publish the consent screen |
| `403 accessNotConfigured` / Drive API disabled | Drive API not enabled in this project | 10.1 step B |
| Works on Android, iPhone sees no data | iOS client created in a different Cloud project | Recreate it in the same project |
| iOS crashes or returns at once when signing in | `GIDClientID` or URL scheme missing from `Info.plist` | 10.2 step 2 |
| Creating the Android client fails: package name and fingerprint already in use | That pair is still registered in another project | Delete the client there first (10.1 step D), wait a few minutes, retry |
| Sync row missing | Build made without `STICKY_SYNC=true`, or iOS (not enabled yet) | Rebuild with the define; 10.2 |

---

## 11. In-app purchases: trust Google Play's answer (every Winka Studio app)

**Decided by the owner, for every app on this account:** an app unlocks a
purchase when **Google Play says it is bought**, through Flutter's
`in_app_purchase` plugin. There is **no on-device signature check** with the
app's licensing key and **no purchase server**. Sticky Wall
(`lib/services/pro_controller.dart`) is the reference.

### Do

- Products are one-time and non-consumable (Sticky Wall: `sticky_wall_pro`).
- Listen to `purchaseStream` before anything else; then load the product with
  `queryProductDetails` and call `restorePurchases()` at start.
- Unlock on `purchased` or `restored`, but only when the Play purchase state is
  really *purchased*. Google reports a purchase still waiting for cash or a
  bank transfer as "restored" too; show that one as **pending** (Sticky Wall:
  `ProController._settled`).
- Call `completePurchase` for every purchase that needs it and is not pending.
  Play refunds a purchase that is not acknowledged within 3 days.
- Keep the unlock cached on the device, so the app works offline.
- Revoke only on a **clear "no"** from Play (`queryPastPurchases` no longer
  lists it: refund, cancelled order). Offline, an error or Play missing keeps
  the unlock. Never stop rendering what the user already made with paid
  things; stop only choosing them.
- The buy button depends only on the product having loaded from Play. When it
  has not (no Play, offline, product not yet active), say so and let the user
  try again.
- Test with **license testers** (Play Console → *Settings → License
  testing*) on a build installed from a testing track.

### Don't

- **Don't add signature verification** with the "Base64-encoded RSA public
  key" from *Monetize with Play → Monetization setup → Licensing*.
- **Don't ask the owner for that key**, and don't put it in code, config,
  `--dart-define`s or local store files.
- **Never disable or hide the buy button because a key or setting is
  missing.** That locks out paying customers: the one failure that costs real
  money.
- Don't build a purchase server or call the Play Developer API's purchase
  endpoints from the app. The service account cannot read orders anyway.

### Why

- On-device verification stops only casual purchase-faking tools. Anyone who
  can root a phone can also patch the check out of the app.
- A wrong or missing key breaks buying for every real customer.
- Prices are small one-time unlocks; the apps are local-first, with no server.
- Real protection would need a server asking Google about each purchase. That
  is a separate decision for the owner, not something to add on the side.

### An app that already has a signature check

Remove it: the verification code, the key setting and its build or config
plumbing, and any rule that disables buying when the key is missing. Keep
everything in **Do** above. Test that a license tester can buy, restore after
reinstalling, and keep the unlock offline.

---

## 12. Production: from closed testing to the public (owner, Play Console)

Production is **never automated**: the service account has no production
rights, on purpose. Everything here is clicked by the owner in Play Console
(https://play.google.com/console). An agent can prepare it (version, notes,
checks with `python tool/play.py check`) and say what is missing, but cannot
press the buttons.

### 12.1 The order, once per app

1. Closed testing runs long enough (12.2).
2. Everything below 12.3 is green.
3. Apply for production access and wait for Google's answer (12.4).
4. Set countries and release the tested bundle to production (12.5).
5. Every later version: closed testing first, then promote (12.6).

### 12.2 Closed-testing requirement (personal developer accounts)

Personal accounts created after 13 Nov 2023 must run a closed test before
production unlocks:
- at least **12 testers opted in, continuously for the last 14 days**;
- testers count only after they **opt in** through the opt-in link
  (*Test and release → Testing → Closed testing → the track → Testers → Copy
  link*) **and** install the app from Play. Being in the Google Group alone
  does not count;
- the **Dashboard** shows the progress ("x testers opted in, y of 14 days").
  If the count drops below 12, the 14 days start again.

Keep shipping versions to closed testing during these 14 days and keep a short
log of tester feedback and what changed: the application in 12.4 asks for it.

Organization accounts skip 12.2 and 12.4.

### 12.3 Before applying: everything that must be ready

Check each page in Play Console. A red or "action needed" item blocks the
release.

| Where | What | Sticky Wall |
|---|---|---|
| *Grow users → Store presence → Main store listing* | Title, short and full description, icon 512, feature graphic 1024×500, at least 2 phone screenshots, in every listed language | en-US and vi complete. **Default language is still `vi`**: switch it to *English (United States)* under *Store settings → Manage translations / default language* if English should lead (the owner's choice) |
| *Grow users → Store presence → Store settings* | Category (Productivity), contact email, privacy policy URL | Email set; website and phone empty (optional) |
| *Policy and programs → App content* | Privacy policy, App access, Ads, Content rating, Target audience, Data safety, Government apps, Financial features, Health, Advertising ID | Answers and reasons: `docs/release/PLAY_LISTING_1_4_1.md` section 4. **Data safety must include:** audio recordings (processed on device, not collected), purchase history handled by Google Play, and opt-in sync to the user's own Google Drive (data not collected by the developer) |
| *Monetize with Play → Products → One-time products* | Product active, with a listing in each store language | `sticky_wall_pro` is active but **only has a `vi` title**: add an `en-US` title and description |
| *Monetize with Play → Payments profile* | Merchant profile verified | Needed to be paid for Pro |
| *Test and release → Setup → App integrity* | Play App Signing on | On |
| Google Cloud, the app's own project | Sync consent screen **In production**, Android clients for the Play app-signing SHA-1 (10.1) | Otherwise sync fails for the public |
| `PRIVACY.md`, the in-app policy link | Matches what the app does | Update together with Data safety |
| Target API level | The bundle meets Play's current target SDK requirement | Flutter's default `targetSdk` normally does; Play Console warns on upload if not |

Clean-up worth doing once: the custom track `1.0` has an empty draft; delete
it in *Test and release → Testing* (the API never deletes anything).

### 12.4 Apply for production access (personal accounts)

1. **Dashboard** → *Apply for production* (appears once 12.2 is met).
2. The form asks, in prose:
   - how testers were recruited and how engaged they were;
   - what feedback came in and what was changed because of it;
   - who the app is for and what it offers;
   - why it is ready for production.
   Answer from the closed-testing log; concrete examples (a fixed bug, an
   added feature) help.
3. Submit. Google answers by email, usually **within 7 days**. If it says no,
   it says why; keep testing and apply again.

### 12.5 The first production release

1. **Countries:** *Test and release → Production → Countries / regions → Add
   countries / regions*. Pick them (all, or start with a few such as Vietnam
   and the US) → Save.
2. **Release the bundle testers already have.** Never rebuild for production:
   the same versionCode that passed closed testing goes out.
   - Either *Test and release → Testing → Closed testing → the track →
     Releases → the release → **Promote release → Production***,
   - or *Production → **Create new release** → Add from library* → pick that
     versionCode.
3. **Release notes:** copy `android/fastlane/metadata/android/en-US/changelogs/N.txt`
   and `.../vi/changelogs/N.txt`. The release name fills itself
   (`1.5.2 (13)` style).
4. **Next → review the summary.** Warnings may stay; errors must be fixed.
   The **first** production release goes to 100% (staged rollout is only for
   updates).
5. **Save → Publishing overview → Send changes for review.** With *Managed
   publishing* on, Play waits for **Publish** after approval; with it off,
   the release goes live once approved. The first production review can take
   up to about a week; later ones usually hours to a couple of days.
6. **After it is live:**
   - open the public store page in each language;
   - install from Play on a clean device; buy Pro with a non-tester account
     (a real charge; refund it from *Order management* if it was only a
     check), restore after reinstall, try sync;
   - watch *Monitor and improve → Android vitals* (crashes, ANRs) and
     ratings for the first days.

### 12.6 Every later version

1. The owner says "publish": section 0 ships it to closed testing.
2. Testers try it (a day or more for anything big).
3. The owner promotes that release to production (12.5 step 2) with a
   **staged rollout**: start at 10–20%, raise it to 50% and then 100% over a
   few days if Android vitals stay calm. *Production → the release → Update
   rollout* changes the percentage; **Halt rollout** stops a bad release
   (fix it, ship a higher versionCode).
4. The version on production is always one that closed testing has had first.

---

## 13. The studio website: legal links

Since 9 Nov 2026 every app's legal pages live on the studio website
**https://winka.top** (Netlify; source repo `Winka173/winka-studio`,
`C:\Users\Winka\Projects\winka-studio`, guide
`GOOGLE_PLAY_POLICY_TERMS_GUIDE.md` there). Each page has an English copy
under `/en/` and a Vietnamese one under `/vi/`; stores and Google Cloud get
the English one.

| Page | Sticky Wall (English) |
|---|---|
| App page | `https://winka.top/en/apps/sticky-wall/` |
| Privacy policy | `https://winka.top/en/apps/sticky-wall/privacy/` |
| Terms of service | `https://winka.top/en/apps/sticky-wall/terms/` |
| Data deletion | `https://winka.top/en/apps/sticky-wall/data-deletion/` |
| Support | `https://winka.top/en/support/sticky-wall/` |

**Where the text comes from:** `PRIVACY.md` is the source of truth; its
halves are copied to `docs/website/legal/privacy.{en,vi}.md`, beside
`terms.{en,vi}.md`. The website imports them from this repo
(`scripts/import-website-kits.py --only sticky-wall` there, into
`src/content/website-kits.json`). Change all three together, then commit and
push the website repo; Netlify publishes it.

**Where each link is used:**

| Where | Value | State (9 Nov 2026) |
|---|---|---|
| The app: *Settings → About → Privacy policy / Terms of service* | `lib/util/legal_links.dart` (`/vi/` when the app is in Vietnamese) | In code; reaches users with the next release |
| Play Console → *Policy and programs → App content → Privacy policy* | Privacy policy | Owner: switch from the GitHub `PRIVACY.md` URL |
| Play Console → *Store presence → Store settings → Store listing contact details → Website* | App page | Owner |
| Play Console → *Policy and programs → App content → Trader status* (EU Digital Services Act) | **Yes, my trader status applies to this app** (Pro is sold, so the app is part of a trade; the developer account is already declared a trader), then *Terms of service*: the terms page | Owner |
| Google Cloud → the app's project → *Google Auth Platform → Branding* (10.1 C2) | Home page, privacy, terms; authorized domain `winka.top` | Owner |
| Google Search Console | Domain property `winka.top` (DNS TXT) | Owner, once for all apps |
| App Store Connect (iOS, later) | Privacy policy URL, support URL, marketing URL | Not set up |

The data-deletion page explains how people delete their own data (on the
phone, and the Drive copy if they used sync). It is not an account-deletion
service: the app has no accounts of its own and no server, so Play's account
deletion requirement does not apply. Keep *Data safety* as it is (the *App content* row in
section 12 above); a new URL changes nothing there.

After switching: open every link logged out, check the consent screen still
says *In production*, and run a sync once on a device. Keep the old GitHub
`PRIVACY.md` in place: builds already installed link to it.
