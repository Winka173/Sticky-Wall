# Sticky Wall — website kit

Everything needed to build Sticky Wall's page on the studio website:
copy in English and Vietnamese, legal pages, brand assets, real screenshots
(phone and large screen) and screen recordings. Start here.

## What Sticky Wall is

A sticky-notes app for Android (iPhone later) that looks and behaves like a
real pin-board: pastel paper notes in handwriting fonts on a textured wall,
which you drag, turn, pin, tie together with yarn and decorate. Seven kinds of
note (text, to-do, link, drawing, photo print, label, voice note), 45 board
templates, 43 theme packs, memory walls of photos, reminders, a home-screen
widget. Everything stays on the phone: no account, no ads, no tracking.
Free, with an optional one-time **Sticky Wall Pro**. English and Tiếng Việt.

**Audience:** everyday planners in Vietnam and beyond — students, families,
people who like paper planners and pin-boards — who want their phone's notes
to feel like a wall, not a list.

**The page's one job:** show the wall (pictures and clips do most of the
talking) and send people to Google Play.

## Folder map

| Path | What |
|---|---|
| `content/landing.en.md` | Page copy in English, section by section, with SEO meta, FAQ and which picture goes where |
| `content/landing.vi.md` | The same page written in Vietnamese |
| `content/app-facts.md` | Fact sheet: ids, links, platforms, every count (checked in code), full feature list, words to avoid |
| `legal/privacy.en.md`, `legal/privacy.vi.md` | Privacy policy pages (from `/PRIVACY.md`, the source of truth) |
| `legal/terms.en.md`, `legal/terms.vi.md` | Terms of service pages (new) |
| `brand/BRAND.md` | Logo files, colours, fonts, materials, voice |
| `brand/logo/` | App icon 1024, layers, Pro badge, favicons, touch icons |
| `brand/og-image-1200x630*.jpg` | Link-preview images (EN, VI) |
| `brand/feature-graphic-1024x500.png` | Google Play feature graphic |
| `brand/fonts/` | Pacifico (wordmark) and Patrick Hand (handwriting) with their licences |
| `screenshots/INDEX.md` | Every screenshot: what it shows, alt text EN/VI |
| `screenshots/phone/{en,vi}/` | 23 phone screens each, 1080 × 2160 WebP |
| `screenshots/desktop/{en,vi}/` | 23 large-screen captures each, 1920 × 1080 WebP |
| `clips/INDEX.md` + `clips/*.mp4` | 7 screen recordings (phone, English) with poster frames |
| `media/walls/` | Every wall texture (JPEG) |
| `media/previews/` | Contact sheets of the templates and theme packs |
| `CREDITS.md` | Photo credits (CC0 / public domain) and font licences |

## Pages the site needs for this app

1. **App page** (EN and VI): from `content/landing.*.md`.
2. **Privacy policy** (EN and VI): `legal/privacy.*.md`. Google Play and
   Google Cloud (the Drive sync consent screen) link to it, so its address
   must stay stable once published.
3. **Terms of service** (EN and VI): `legal/terms.*.md`.

Suggested addresses, matching the plan in
`/docs/release/PLAY_CONSOLE_API_GUIDE.md` §13: `/sticky-wall/`,
`/sticky-wall/privacy/`, `/sticky-wall/terms/`, with `/vi/` variants (or a
language switch on the same page).

Also worth having: a language switch (EN / VI), a "Get it on Google Play"
badge (Google's official badge artwork from its badge generator), a short
press/about block with the icon and feature graphic, a footer with privacy,
terms, contact and photo credits, `hreflang` links between EN and VI,
and the favicons in `brand/logo/`.

## Decisions for the owner (not settled in this kit)

- **Download button:** the app is on Google Play *closed testing*; the public
  store link works only after production release. Until then use "Coming
  soon to Google Play" or a tester sign-up.
- **iPhone:** not on the App Store. The FAQ suggests "An iPhone version is
  planned"; confirm or drop it.
- **Governing law** in the terms is set to Vietnam; confirm.
- **Contact:** the kit uses `apps.winka.studio@gmail.com` (the Play support
  address). The privacy policy still says "open a GitHub issue"; when the
  site goes live, change its Contact section in `/PRIVACY.md` and here.
- **Price:** never write a price on the page. `21_pro` shows the current test
  price on the button; crop or blur it, or leave that screenshot out.

## After the site is live

Follow `/docs/release/PLAY_CONSOLE_API_GUIDE.md` §13: point Play Console's
privacy policy and website fields, the Google Cloud Branding page and the
app's own privacy link (`privacyPolicyUrl` in
`lib/widgets/settings_sheet.dart`, plus the "Terms of service — coming soon"
item) at the new addresses.

## How the screenshots and clips were made (to redo them)

- Sample data: `test/website_seed_test.dart` writes backup files (EN / VI ×
  phone / wide layouts) with the same boards, notes and photos:
  `flutter test test/website_seed_test.dart --dart-define=WEBSITE_SEED=true --dart-define=WEBSITE_PHOTOS=<folder with the photos in CREDITS.md>`
  → `build/website_seed/*.json`, loaded in the app with *Settings → Backup &
  restore → Restore backup → Replace everything*.
- Device: a BlueStacks Android 11 instance, 1920 × 1080 for "desktop" and
  `adb shell wm size 1080x2340` + `wm density 420` for phone (BlueStacks caps
  it at 1080 × 2160); status bar via SystemUI demo mode (clock 09:41).
- Captures: `adb exec-out screencap -p`, converted to WebP q90; clips with
  `adb shell screenrecord`.
