# The first-run guide and How to use

The first run used to show a welcome sheet with three choices, and "Explore"
started a coach card over the real wall. Both are gone. In their place:

- a full-page **first-run guide** in three stages (`lib/welcome/welcome_guide.dart`);
- **How to use**, in Settings → Help, which replays the guide or opens the
  manual as short topics (`lib/welcome/how_to_use.dart`).

## When it shows

- `main.dart` seeds the sample notes on a first run and sets
  `welcomePending`, as before. The home screen opens the guide on the first
  frame while `welcomePending` is set. Someone who already has a wall never
  has it set, so never sees the guide.
- Skip, Android back on the first beat, and Start all close it. Either way
  `welcomePending` and `tipsPending` are cleared (the guide covers the
  gesture tips). If the app is killed mid-guide, it shows again next time.

## Flow

A progress bar of three segments reads "Step n of 3" to a screen reader.
Back (from the second beat on) and Skip are on every stage. Android back and
Esc step back. Enter presses the stage's button when no other control has
the focus.

1. **Story**, one stage with two beats on one scene widget (`story_scene.dart`),
   so the papers really travel.
   - **1a.** "Notes everywhere. / Found nowhere." A receipt, a torn sticky, a
     phone note and a napkin drop in with an overshoot, land scattered and
     turn grey. Button: **Put them on a wall**.
   - **1b.** "One wall for all of it." The same four papers fly onto a cork
     wall and become the app's own sticky cards (`StickyNoteCard`, on
     `WallBackground`). A red yarn is strung between two of them. "On your
     phone. No account, no ads." Button: **Show me how**.
2. **Practice** on a pretend wall (`practice_wall.dart`), full screen at
   real size on phones. Its notes are built on the spot and never reach
   `NotesController`: nothing is saved. Everything is dark except the one
   target, in a lit window (warm glow, chalk edge, a ring that breathes three
   times and then rests) with a label beside it. It glides to the next
   target. A line at the top says what is on screen.
   - Tap the yellow paper: "Water the plants" (VI "Tưới cây") pops onto the
     wall.
   - Drag it onto the dashed spot.
   - Pull its red pin onto "Saturday" (any other note counts too): a thread
     ties them.
   - **Next** at the bottom left does the current step for anyone who cannot
     make the gesture.
   - When done, the dark lifts, a check pops, and a panel rises: "That's the
     wall." The words say nothing was saved. Button: **Next**.
   - Back into the practice starts it afresh.
3. **Make it yours.** Three large choices, Explore chosen to begin with:
   - **Start with a blank wall**: `NotesController.discardSamples`.
   - **Pick a template**: `GalleryScreen.open` into the current board. A
     template used replaces the samples; backing out keeps them.
   - **Explore the sample wall**: keeps the samples (as Skip does).
   - **Restore a backup** (someone moving from another phone): the backup
     file dialog and its preview, as in Settings (`restoreBackup` in
     `settings_sheet.dart`), with no Settings page around them. Once a
     backup is in, the samples go; cancelling keeps them.

   Button: **Start**.

The guide asks for no permission, purchase, sign-in or sync.

## Replay and How to use

Settings → Help has one row, **How to use**. The Gesture tips row was
removed: everything it said is in the manual's topics.

- **Replay the guide** runs the same three stages. On a replay the last
  stage shows no choices: it says where templates and new boards are, and
  its button is **Done**. Replay changes nothing (tested).
- **Topics**, each with a one-line summary, open one short page each: a
  title, one still picture, and two to four numbered steps. Previous and
  Next walk through all twelve in order; Next on the last one is Done.
  1. Your first note: a still of the practice's add step.
  2. Moving and arranging: the move step; the grips, two-finger twist and
     pinch, Arrange…, Undo.
  3. Threads between notes: the tie step, with a thread half pulled.
  4. Kinds of notes and reminders: what the yellow paper offers, voice
     notes, reminders (once or repeating), Lock in place.
  5. Drawing on the wall: pen, highlighter, eraser (one line at a time),
     Undo, Done.
  6. Boards and the Trash: tabs, the + tab, dropping a note on a tab, the
     Trash for 30 days.
  7. Templates and themes: the gallery, Clear the examples, what a theme
     changes, the open tab's menu (edit, theme, lock, delete).
  8. Photos and memory walls: long-press an empty spot, Pin photos, Memory
     wall.
  9. Search and views: accent-free search, Wall / Grid / List (in the tool
     pill), Select notes and the loop.
  10. Share and export: Share / Save image on a note, Export board as image
      or PDF, sharing into Sticky Wall from other apps.
  11. Keeping it safe: Back up notes and the weekly automatic copy, moving
      to a new phone (back up, send the file, Restore backup), Sync (only in
      builds with `STICKY_SYNC`), App lock and locked boards. Restoring is
      taught here, not in the guide.
  12. Make it yours: Customize (walls, handwriting, pins, try-on), Lights
      off and its schedule, the home-screen widget, the language.

  The pictures are inert: no pointer, no focus, hidden from screen readers,
  drawn at rest.

The drawing tip in the gesture-tips sheet (still offered once to anyone
whose tips were pending) now names the eraser instead of the removed "clear"
button.

## Look

- The ground is the theme's paper (`colorScheme.surface`), dimmed with the
  lights off. Titles are in the chosen handwriting face, balanced by
  `noteFontScale`. Body text is Be Vietnam Pro. Ink is `AppColors.ink`.
- The accent is `AppColors.accent`: the progress bar, a highlighter band drawn
  in under each title's key words, the lit window's glow, the check, and the
  primary button (from the theme's `FilledButton`).
- Cork is the app's own `cork` wall texture. Notes are the real cards.

## Motion

- One clock per stage and per story beat, 1.5 s, restarted on each change.
  The title rises with an overshoot (0–35 %), the band draws in (30–70 %),
  the body follows (12–50 %), and the button scales in (60–95 %).
- The lit window glides in 520 ms. Its ring breathes for 1.4 s, three times.
- With the system's reduce-motion setting everything is at rest at once.

## Layout

- **Under 700 px, story:** the bar, then the title and one line, centred. The
  scene takes the height left, with a full-width 56 px button at the foot.
  Below 600 px of height, or with text above 130 %, the words and scene
  scroll between the fixed bar and the fixed button.
- **Under 700 px, practice:** the wall fills the screen edge to edge, and the
  bar floats on top in chalk. Text inside the practice is clamped to 150 %
  so the wall can hold it. The closing panel is at most 62 % of the height
  and scrolls.
- **Under 700 px, last stage:** the bar, the words and the choices scroll,
  and Start sits at the foot.
- **700 px and up:** the words and button are on the left (flex 5). The
  scene, practice wall or choices are on the right (flex 6). Content is at
  most 1180 px wide.

## Accessibility

- Titles are headers, read without the line break. The progress bar is one
  "Step n of 3" node.
- The add button is named ("Add to your wall"). The lit label and the top
  line are live regions. The practice's Next does each gesture for screen
  reader users.
- The choices are selectable buttons in one group, with their hint in the
  label. They are reachable by keyboard (`KeyboardTappable`).
- Every target is at least 48 dp. Skip is always there.

## Checked

- `test/welcome_guide_test.dart` (18 tests):
  - a first run shows the guide; Skip is remembered across a restart and
    keeps the samples;
  - existing users never see it;
  - three stages with Back;
  - the practice done by its real gestures (tap, drag, pin pull) leaves the
    notes, links and boards unchanged;
  - Android back;
  - Blank removes the samples and their thread, with nothing in the Trash;
  - Explore keeps them;
  - Template opens the gallery, and backing out keeps the samples;
  - How to use: replay changes nothing and its last stage only closes;
    topics open, and Previous and Next walk all twelve;
  - Restore a backup opens the backup dialog, and cancelling keeps the
    samples;
  - no overflow for every guide stage at 320×640 @ 200 %, 390×844 and
    1280×800, and for every topic at 320×640 @ 200 % and 390×844, in EN and
    VI.
- `test/gallery_test.dart` goes through the guide for blank, template and
  explore. `test/app_settings_test.dart` lists How to use.
- Screenshots: `test/welcome_guide_preview_test.dart`, skipped unless run
  with `--dart-define=GUIDE_CAPTURE=true`. It writes to
  `output/first_run_guide/` (git-ignored) at 390 and 320 px (EN), 320 px
  @ 200 % (VI), 390 px with the lights off (VI) and 1280 px.
- Not yet run on a device. The pin-pull and drag in the practice use the
  card's real pin recognizer and a plain pan, so they need an on-device
  check, as all gesture changes do.
