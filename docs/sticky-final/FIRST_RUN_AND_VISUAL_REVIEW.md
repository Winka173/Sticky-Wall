# First run and visual review

## First run

A fresh install shows the sample wall and a welcome sheet with three choices:

1. **Pick a template**
2. **Start with a blank wall**: removes the examples.
3. **Explore the sample wall**: starts the **interactive guide**.

### The interactive guide

- **Steps** (a card above the tool pill):
  1. Tap a note.
  2. Drag a note.
  3. Tie two notes with a thread.
  4. Write your first note.
- **Moving on:** each step moves on when the gesture is done.
- **Without the gesture:**
  - **Next** is always there.
  - The thread step also names the menu route, "Tie a thread to…".
  - **Skip** ends the guide.
- **Accessibility:**
  - The card is a live region for screen readers.
  - Buttons are at least 44 dp tall.
  - The buttons wrap at large text.
- **No side effects:** the guide never creates or deletes anything, and needs no permissions, billing or sign-in.
- **Replay:** More menu → **Interactive guide**, on the current wall, without touching its data.

## Layout of the sample notes

| Screen | Layout |
|---|---|
| Phone, portrait | The hand-tuned two-column layout |
| Wide screen | Rows of up to five, centred, a little above the middle |

Verified by `test/sample_layout_test.dart` (7 screen sizes: no overlap, pins never covered) and by a screenshot on BlueStacks at 960×540: five notes in one even row.

## Visual fixes in this pass (earlier commits)

- **Pin thread drag:** the pin catches a drag after 6 px, and the grab band is 64×44.
- **Search fields:** the icon is centred on the text line, and the template search is a rounded field.
- **Copy:** the glossary pass for EN and VI.

## Not done

- **Templates and themes:** a full audit of the 45 templates and 37 themes at 320 dp and at 200 % text.
- **Memory Wall:** the step reorder (photos → live preview → create).
- **Wall toolbar:** merging Tidy and Arrange.
- **Screen readers:** a TalkBack or VoiceOver session.
