# Connecting a repo to Google Play Console (Winka Studio)

How any app repo of the **Winka Studio** developer account talks to Google Play
through the Developer API with fastlane. Sticky Wall
(`com.apps.winka.stickywall`) is the working reference: copy from its
`android/fastlane/` and `tool/play.py`.

## 1. What already exists (shared by every app)

| Item | Value |
|---|---|
| Developer account | Winka Studio (personal account), id `5080364487976666246` |
| Google Cloud project | `play-publisher-513712`, with *Google Play Android Developer API* enabled |
| Service account | `play-publisher@play-publisher-513712.iam.gserviceaccount.com` |
| Key file | `C:\Users\Winka\.secrets\play-publisher.json`, or the path in env `PLAY_KEY`. **Never copy it into a repo, never print it.** |
| Permissions | Account-level, so every app on the account is covered, including apps created later: view app info, manage store listing, release to testing tracks, manage testing tracks and testers, manage in-app products. **No** production release, financial data, orders, users or admin. |
| Ruby / fastlane | Ruby 3.3 at `C:\Ruby33-x64\bin` (add it to `PATH`); fastlane 2.241 installed as a gem |

Nothing has to be created again for a new app.

## 2. What the API cannot do (do these in the Play Console web UI)

- **Create the app.** No API exists for it.
- **Upload the very first bundle.** Until one build exists, the API answers
  *"Package not found"*.
- **App content forms:** privacy policy URL, app access (sign-in details), ads,
  content rating (IARC), target audience, data safety, advertising ID,
  financial features, government or health declarations.
- **Store settings:** category, tags, external marketing.
- **Money:** merchant profile, promo codes, license testers.
- **Production:** releasing to production, and applying for production access
  after the closed test (personal accounts: at least 12 testers opted in for 14
  days in a row).

Sticky Wall's answers to these forms, with the reasons, are in
`docs/release/PLAY_LISTING_1_4_1.md` (section 4) of the Sticky Wall repo. Reuse
them where the new app behaves the same, and recheck each answer against the new app.

## 3. New app, step by step

1. **Play Console → Create app.**
   - Choose the name and **default language English (United States)**. Other
     countries see the default language.
   - Choose app or game, and free or paid.
   - Accept the declarations.
2. **In the repo:**
   1. Fix the `applicationId`. It can never change after the first upload.
   2. Create an upload keystore. Keep it outside the repo, like
      `C:\Users\Winka\sticky-wall-upload.jks`; one keystore per app is
      fine.
   3. Add a gitignored `android/key.properties` pointing to the keystore.
   4. Wire it into `signingConfigs.release`.
   5. Set the version in `pubspec.yaml` as `x.y.z+versionCode`.
3. **Build:**
   `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`.
   Keep `build/symbols/` to read crash stack traces later.
4. **Upload this first `.aab` by hand:**
   - Go to Play Console → *Test and release → Internal testing → Create release*.
   - Accept Play App Signing.
   - Saving the release as a draft is enough. After this the API can see the package.
5. **Copy fastlane:**
   - Copy `android/fastlane/Appfile` and `android/fastlane/Fastfile` from Sticky
     Wall and change `package_name` in `Appfile`. The Fastfile reads the
     version from `pubspec.yaml`. For a non-Flutter app, adapt `pubspec_version`.
   - Add to `.gitignore`:
     ```
     android/fastlane/metadata/android/*/images/
     android/fastlane/report.xml
     android/fastlane/README.md
     ```
   - Add to `.gitattributes`: `android/fastlane/metadata/** text eol=lf`.
     Without it, Windows line endings end up inside Play text.
6. **Check the connection** from `android/`: run `fastlane android check`
   (read-only). A healthy run ends with *"fastlane.tools finished successfully"*.
7. **Store listing text:**
   - Write `android/fastlane/metadata/android/<lang>/{title,short_description,full_description}.txt`
     for `en-US` and `vi`. Limits are title ≤ 30, short ≤ 80, full ≤ 4000.
   - Run `fastlane android metadata`.
   - Upload graphics in the web UI, or with `upload_to_play_store` with images
     enabled:
     - icon: 512×512, 32-bit PNG;
     - feature graphic: 1024×500;
     - 2–8 phone screenshots: 9:16, each side ≥ 1080 px to qualify for promotion.
8. **Each release after that:**
   1. Bump `version:` in `pubspec.yaml`. The versionCode must be higher than
      every code ever uploaded, on any track.
   2. Write `metadata/android/{en-US,vi}/changelogs/<versionCode>.txt`
      (≤ 500 characters).
   3. Run `fastlane android build`, then `fastlane android closed` (or `internal`).
   4. The release arrives as a **draft**. Open *Publishing overview → Send
      changes for review* in the web UI.

`tool/play.py check <package>` (from Sticky Wall, needs `pip install
google-auth google-api-python-client`) prints a fuller read-only report: the
default language, every listing with its lengths, image counts per type,
tracks with releases and testers, uploaded version codes and one-time products.

## 4. Environment for a shell (Windows, Git Bash)

```sh
export PATH="/c/Ruby33-x64/bin:$PATH"
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8          # fastlane needs UTF-8
export FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_HIDE_CHANGELOG=1 FASTLANE_OPT_OUT_USAGE=1
cd android && fastlane android check
```

## 5. When something fails

| Message | Cause | Fix |
|---|---|---|
| `The caller does not have permission` | The service account is not invited, the invite went to another account, or permissions have not propagated | Check *Account management → Users and permissions*; wait up to a few hours after inviting |
| `Package not found` | No build was ever uploaded for this app | Do step 4 by hand |
| `APK specifies a version code that has already been used` | That versionCode exists on some track, even a discarded draft | Bump the `+N` in `pubspec.yaml` and rebuild |
| `Only releases with status draft may be created on draft app` | The app has never been reviewed | Keep `release_status: "draft"` (the lanes already do) |
| Pro or in-app product calls fail | Products need a bundle with the billing permission uploaded first, and a merchant profile | Upload a build, then create the product in *Monetize with Play → Products* |
| `download_from_play_store` errors at the end | It errors after the images, but the text is already saved | Check that `metadata/android/<lang>/*.txt` exist; rerunning refuses while the folder exists |

## 6. Rules

- The key is the account. Read it only from `PLAY_KEY` or `~/.secrets/`.
  Never commit, print, paste or upload it. If it leaks, delete it in Cloud
  Console (*IAM & Admin → Service Accounts → play-publisher → Keys*) and make
  a new one.
- Ask the account owner before any write: listing text, uploads or products.
  `check` and `tool/play.py check` are safe to run any time.
- Production releases stay manual; the key deliberately cannot do them.
