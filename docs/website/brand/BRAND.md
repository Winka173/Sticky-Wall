# Sticky Wall — brand kit

## Logo and icons (`logo/`)

| File | Use |
|---|---|
| `app-icon-1024.png` | The app icon, full colour, 1024 px (a sticky note pinned on cork). Use it as the logo mark. |
| `app-icon-foreground-1024.png` / `app-icon-background-1024.png` | The two layers of the Android adaptive icon, for compositions. |
| `splash-logo-1024.png` | The mark on a transparent ground, as on the launch screen. |
| `play-icon-512.png` | The icon as uploaded to Google Play. |
| `pro-icon-512.png` | The Sticky Wall Pro badge. Only next to Pro content. |
| `favicon.ico`, `favicon-16/32/48.png`, `apple-touch-icon-180.png`, `icon-192.png`, `icon-512.png` | Ready-made web icons cut from the app icon. |
| `../feature-graphic-1024x500.png` | Google Play feature graphic (good for a banner or press). |
| `../og-image-1200x630.jpg`, `../og-image-1200x630-vi.jpg` | Link previews, cut from the real wall screenshot. |

The wordmark is the words **Sticky Wall** set in **Pacifico** (white on the
wall, ink on paper), exactly as the app's header draws it. There is no
separate wordmark file; set it as live text.

## Colours

Taken from `lib/theme.dart` (`AppColors`).

| Token | Hex | Role in the app |
|---|---|---|
| Ink | `#3B372F` | Text on paper and light grounds (warm near-black, never pure black) |
| Ink soft | `#3B372F` at 92% | Secondary text |
| Paper | `#FFF9E6` | Sheets, dialogs, light surfaces |
| Accent (sunny yellow) | `#FFCA28` | The primary action (Add, Unlock, Share), small badges |
| Pro ink | `#8A5300` | Pro words and icons on paper |
| Pin red | `#D32F2F` | Push-pins, the classic red thread `#C62828` |
| Link | `#123A73` | Links on paper |
| Chalk | `#FDFBF3` | Text written straight on dark walls |
| Print white | `#FCFAF4` | The border of a photo print |
| Shadow | `#302318` | Warm shadow under cards |

**Note papers (free six):** yellow `#FFF59D`, pink `#F8BBD0`, mint `#B2DFDB`,
blue `#B3E5FC`, orange `#FFE0B2`, lilac `#E1BEE7`.
**Pro papers:** lime `#E6EE9C`, coral `#FFCCBC`, periwinkle `#C5CAE9`, sage
`#D6E2C3`, kraft `#E4D2B0`, white `#FAFAF7`.

**Yarn:** red `#C62828`, orange `#EF6C00`, gold `#F9A825`, green `#2E7D32`,
blue `#1565C0`, purple `#6A1B9A`, ink `#3B372F` (Pro: pink `#D81B60`, teal
`#00897B`, brown `#8D6E63`, white `#F5F2EA`).

**Night ("Lights off"):** the app dims to a warm, lamp-lit look, never a
grey dark theme. A dark mode for the site should follow the same idea: warm
browns and dimmed papers, not cool greys.

## Typography

| Font | Where | Licence | Google Fonts |
|---|---|---|---|
| Pacifico | The "Sticky Wall" wordmark only | SIL OFL (`fonts/OFL-Pacifico.txt`) | yes |
| Patrick Hand | The app's handwriting on notes and in the UI; good for headings and note-like accents | SIL OFL (`fonts/OFL-PatrickHand.txt`) | yes |
| Be Vietnam Pro | The app's readable face for long notes; a good body font for the site | SIL OFL | yes |

All three carry the full Vietnamese alphabet. The `.ttf` files in `fonts/`
are the exact ones the app ships.

## Materials

The look comes from real materials: the wall textures in `../media/walls/`
(cork, chalkboards, brick, plaster, wood, kraft, marble, terrazzo, denim,
felt, linen, cardboard, cement, cotton, paper, moss, leather, dark marble,
dark planks, tiles…). Paper cards have a slight hand-stuck tilt, a pin or a
strip of tape, and a soft warm shadow. Threads are red yarn by default.

## Voice

Plain, warm and concrete, like a note on the fridge. Short sentences. Talk
about what a person does ("Tie two notes with yarn"), not features in the
abstract. No hype words, no exclamation marks, no "revolutionary". Vietnamese
copy is written natively, not translated word for word; it uses the app's own
terms (tường, bảng, ghi chú, ghim, dây, Thùng rác, Tắt đèn).
