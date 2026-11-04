# Sticky Wall — visual asset brief and handoff log (1.4.1)

## Who does what

**Image generation (Codex)**
- Draws the illustrated stickers and washi tapes as sheets.
- Writes a manifest of names in English and Vietnamese.
- Checks sizes and backgrounds itself.

**App side (this repo)**
- Keys the sheets to real alpha and bundles them.
- Writes the asset manifest with checksums.
- Wires the assets into the sticker picker, templates and themes, and tests them.

**Drawn in code instead (sharper at any size, no download cost)**
- The photo frames: plain print, Polaroid, film strip, vintage deckle, torn paper, rounded, scrapbook (`lib/widgets/photo_frames.dart`).
- The pins.
- The paper rulings.

## Where assets go in the app

| Asset | Where it shows | File / size | How it is read |
|---|---|---|---|
| Illustrated sticker | Sticker picker shelves; a sticker note on the wall (about 60–120 dp wide); template boards | `assets/stickers/art_<id>.webp`, longest edge ≤ 360 px, transparent | `StickerKind.image` in `lib/widgets/stickers.dart`; the list is generated into `lib/widgets/sticker_assets.g.dart` |
| Washi tape | The *Washi tape* shelf; a long, low sticker (two picker cells, 95% of the card width on the wall) | `assets/stickers/art_tape_<id>.webp`, about 360 × 75 px | Same; the aspect ratio (< 0.6) makes it a long sticker |

## Specification given to Codex (every batch)

- **Originality:** original artwork, commercially usable. No brand, logo, mascot, character or copyrighted design. No text, letters or numbers. No people.
- **Style:** cute, clean, hand-drawn flat illustration; soft shading; thin dark-brown outline; white die-cut border of about 8 px; warm, slightly muted colours that sit on pastel paper and cork. Batch 1 is the reference, and later batches got its contact sheet as a style reference.
- **Sticker sheets:** 1024 × 1024 PNG, a 3 × 3 grid, at least 40 px clear around each sticker. One flat `#00FF00` background, with no bright pure green inside the art.
- **Tape sheets:** 1536 × 1024 PNG, a 2 × 3 grid of horizontal strips about 420 × 90 px, with torn ends.
- **Manifest:** `out/manifest.json` with sheet, row, col, id, en, vi and category for every cell.
- **No-tool rule:** if the image tool is not available, say so and create nothing.

## Import, checks and budget

`python tool/import_art.py <batch> <folder> …` does the following:

1. **Cuts** each grid cell out of its sheet.
2. **Keys** the bright flat green to transparency. Only the rim next to it is despilled, so mint, leaves and avocados keep their colour (the first version greyed them; fixed in `f47cdce`).
3. **Trims** the art and **saves** it as WebP (lossy with alpha, q88).
4. **Writes** `docs/design/STICKY_VISUAL_ASSET_MANIFEST.json`: path, width, height, bytes, SHA-256, batch, category, shelf, free or Pro, names, source, licence.
5. **Writes** the Dart list and one contact sheet per category on a cork and a dark ground: `docs/design/STICKY_VISUAL_CONTACT_SHEETS/`.
6. **Refuses** duplicate ids and byte-identical files.

`test/template_library_test.dart` checks the result:

- Every manifest entry is a bundled file of the stated size.
- The app lists every entry as a sticker with both names and the right free or Pro flag.
- The free app has at least 20 illustrations.

Memory budget:

- Pictures are decoded at 128–384 px wide, in steps of 64 (`stickerCacheWidth`), never at full size.
- The picker builds shelves lazily inside a scroll view.

Size budget: about 10 KB per sticker; all four batches total 2.0 MB for 197 files.

## Handoff log

| Batch | Sent | Asked for | Received | Review | Integrated |
|---|---|---|---|---|---|
| b1 | 2026-11-04 | 4 sticker sheets (study, home, Vietnam, feelings) = 36 | 4 sheets + manifest, 1024² | Approved as is: consistent style, clean flat ground, no text or brands | 36 (27 free, 9 Pro) |
| b2 | 2026-11-04 | 4 sticker sheets (nature, food, travel, planner) + 2 tape sheets = 48 | 6 sheets + manifest | Approved. Importer bug (greens greyed) found on the tape sheet and fixed on our side | 48 (9 free, 39 Pro) |
| b3 | 2026-11-04 | 6 sticker sheets (animals, hobbies, cozy, Tết & Mid-Autumn, holidays, love) + 2 tape sheets = 66 | 8 sheets + manifest (Codex redrew a brown checkerboard tape as black and white on its own review) | Approved; the `sw3_` id prefix Codex added was dropped on import | 66 (Pro) |
| b4 | 2026-11-04 | 4 sticker sheets (sea & beach, garden, note marks, desk & office) + 2 tape sheets = 48 | 6 sheets + manifest | 47 approved. Wireless earbuds dropped (too close to a known product). Tape ids repeated batch 2's although the brief forbade it; renamed from their English names on import. | 47 (9 note marks free, the rest Pro) |

**Totals in the app:** 161 illustrated stickers (45 free) and 36 washi tapes (Pro), 197 files, about 2.0 MB.

Not commissioned in this pass (with the reason):

- **Theme moodboards (Batch A):** they do not ship in the app.
- **Pin, paper-grain and wall-texture bitmaps:** the pins and rulings are code-drawn and already sharp. A grain bitmap under every card would cost a texture draw per note on big walls.
- **Store graphics (Batch D):** they wait for on-device screenshots.
