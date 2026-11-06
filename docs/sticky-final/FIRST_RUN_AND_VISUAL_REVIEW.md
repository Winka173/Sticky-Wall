# First run and visual review

## First run

The welcome sheet and the overlay "interactive guide" described here before
were replaced by a full-page first-run guide and a *How to use* page in
Settings → Help. See `FIRST_RUN_GUIDE.md`.

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
