# Start here

- `docs/HANDOFF.md`: where the project stands, the owner's working rules,
  how to build and test, and what is still open.

# Repository workflow

- After completing the user's requested changes and the appropriate checks,
  commit the changes belonging to that task and push the current branch to its
  configured upstream. This is the owner's standing preference.
- Preserve unrelated or unfinished work from the user and other agents. Stage
  the task's files deliberately; never force-push or discard work to make a push
  succeed.
- Report the commit hash, branch and push result. Keep credentials, signing keys,
  build outputs and local review artifacts out of commits.
- A later explicit request to pause, cancel, or avoid committing/pushing overrides
  this default. Do not commit incomplete work merely because a turn ends.

# Releasing to Google Play

- Everything is in `docs/release/PLAY_CONSOLE_API_GUIDE.md`. Read it before
  building for the store, publishing or changing the listing. It covers a fresh
  machine, the secrets, every fastlane lane and `tool/play.py` command, store
  screenshots, and a new app.
- When the owner says "publish":
  1. Bump `version: x.y.z+N` in `pubspec.yaml`. `N` must be above
     `python tool/play.py codes`.
  2. Write `android/fastlane/metadata/android/{en-US,vi}/changelogs/N.txt`,
     at most 500 characters each.
  3. Run analyze and the full tests, then commit and push.
  4. Run `cd android && fastlane android publish`. It checks, builds with sync,
     uploads to closed testing and rolls out.
- Production stays manual: the service account cannot release to it.
- Secrets stay outside the repo and are never printed:
  `~/.secrets/play-publisher.json`, the upload keystore, and the gitignored
  `android/key.properties`.
- Store marketing screenshots come from the `app-store-screenshots` skill,
  pinned in `skills-lock.json`. Restore it with
  `npx skills experimental_install`. Scaffold its editor outside this repo.
