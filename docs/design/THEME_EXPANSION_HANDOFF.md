# Theme and paper expansion

Six new complete board looks bring the catalog to 43 themes: 20 Free and 23 Pro.
The original 37 IDs and their entitlements stay unchanged.

| Theme | Vietnamese | Tier | Paper |
| --- | --- | --- | --- |
| Sunny Kitchen | Bếp nắng | Free | Soft flecks |
| Lilac Desk | Bàn tím dịu | Free | Soft flecks |
| Garden Sketches | Phác thảo vườn | Free | Soft flecks |
| Berry Scrapbook | Scrapbook mâm xôi | Pro | Stitched edge |
| Night Observatory | Đài sao đêm | Pro | Dots |
| Seaside Postcards | Bưu thiếp ven biển | Pro | Stitched edge |

Soft flecks is a new Free paper; stitched edge is a new Pro paper. Both work
on text, checklist and link notes. The editor lists Free paper choices first;
locked choices retain the existing Pro flow. These are deterministic vector
patterns drawn by the same painter in previews, the editor and saved notes.
Old paper enum names and indices remain stable; no migration is required.

Each new Pro theme has a Free alternative for template fallback. Applying a
theme continues to use the existing controller and undo path; text, media,
positions and links are preserved. No new paid asset or entitlement mechanism
was introduced.

Verification:

- Full Flutter suite: 376 passed, 64 opt-in tests skipped; also passed in an
  isolated worktree containing only this task's changes.
- Analyzer: no issues. Catalog audit covers every theme at 320 dp and 200%
  text in English and Vietnamese, plus paper contrast checks.
- Added regression checks for all 37 existing Free/Pro entitlements, new
  themes and fallbacks, and paper JSON compatibility.
- Inspected all six production ThemePreview renders in Vietnamese, generated
  English variants, and real Android release screenshots of the catalog and
  new Free/Pro previews. Free shows Apply; locked Pro shows Unlock with Pro.
- Regenerated manual assets and corrected their version metadata to read
  pubspec.yaml instead of a hardcoded earlier release.
- Release APK 1.5.1+12 installed with `-r` and launched on both running
  BlueStacks instances (5556 and 5575), preserving their app data.

Local review: `output/theme_expansion/review.html`, also linked from the top
of `output/visual_polish/review.html`. Device screenshots are identified
separately from Flutter test renders. Build outputs and local review artifacts
are deliberately ignored by Git.

Unrelated custom-color work in the shared checkout was preserved and excluded
from this commit. Manual assets staged for the task were generated separately
against the task's sources so a clean checkout passes the freshness guard.
