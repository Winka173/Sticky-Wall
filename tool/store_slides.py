"""Builds the Google Play screenshots from the website kit's real captures.

Each slide is the app's own screen, large, under a short headline written on
a sticky note pinned to cork. Google Play's rules shape it: no device frame,
the caption keeps under a fifth of the picture, and the first slides show the
real app. Phone slides are 1080x1920; tablet slides 1920x1080.

    python tool/store_slides.py            # writes store/screenshots/<lang>/

Needs Microsoft Edge (or Chrome) for headless rendering. The pictures are
then copied to android/fastlane/metadata/android/<lang>/images/ and uploaded
with `fastlane android images`.
"""

from __future__ import annotations

import html
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
KIT = ROOT / 'docs' / 'website'
OUT = ROOT / 'store' / 'screenshots'
FONT = (KIT / 'brand' / 'fonts' / 'PatrickHand-Regular.ttf').as_uri()
CORK = (KIT / 'media' / 'walls' / 'wall_cork.jpg').as_uri()

BROWSERS = [
    r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Google\Chrome\Application\chrome.exe',
    '/usr/bin/google-chrome',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
]

# (capture, English headline, Vietnamese headline, note paper colour)
PHONE = [
    ('01_wall_home', 'Sticky notes on a real wall',
     'Giấy nhớ trên bức tường thật', '#FFF59D'),
    ('06_editor_checklist', 'To-do lists you tick on the wall',
     'Tích việc ngay trên tường', '#B3E5FC'),
    ('07_editor_text', 'Reminders in one tap',
     'Nhắc việc chỉ một chạm', '#F8BBD0'),
    ('02_wall_memory_trip', 'Turn a trip into a memory wall',
     'Tường kỷ niệm cho chuyến đi', '#FFE0B2'),
    ('03_wall_work_board', 'Plan your work on a chalkboard',
     'Kế hoạch trên bảng phấn', '#B2DFDB'),
    ('13_templates', '45 boards ready to start',
     '45 mẫu bảng có sẵn', '#E1BEE7'),
    ('16_customize', '31 walls, 16 handwriting fonts',
     '31 tường, 16 phông chữ tay', '#FFF59D'),
    ('19_settings', 'No account. No ads. Just yours.',
     'Không tài khoản, không quảng cáo', '#F8BBD0'),
]

TABLET = [
    ('01_wall_home', 'Your whole week on one wall',
     'Cả tuần của bạn trên một bức tường', '#FFF59D'),
    ('02_wall_memory_trip', 'Turn a trip into a memory wall',
     'Biến chuyến đi thành tường kỷ niệm', '#FFE0B2'),
    ('03_wall_work_board', 'Plan your work on a chalkboard',
     'Lên kế hoạch trên bảng phấn', '#B2DFDB'),
    ('14_themes', '37 themes in one tap',
     '37 chủ đề, đổi trong một chạm', '#E1BEE7'),
]


def page(width: int, height: int, shot: pathlib.Path, words: str,
         paper: str, tablet: bool) -> str:
    """One slide as a page of its exact pixel size."""
    band = round(height * (0.17 if not tablet else 0.18))
    note_w = round(width * (0.84 if not tablet else 0.6))
    note_h = band - (40 if not tablet else 34)
    font = 92 if not tablet else 74
    if len(words) > 30:
        font = 80 if not tablet else 66
    shot_w = round(width * (0.88 if not tablet else 0.8))
    radius = 40 if not tablet else 28
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
@font-face {{ font-family: Hand; src: url('{FONT}'); }}
* {{ box-sizing: border-box; margin: 0; }}
html, body {{ width: {width}px; height: {height}px; overflow: hidden; }}
body {{ background: #6b4a2b url('{CORK}') repeat; background-size: 512px; position: relative; }}
.shade {{ position: absolute; inset: 0; background: radial-gradient(ellipse at 50% 0%, rgba(255,240,210,.18), rgba(30,20,10,.28) 75%); }}
.note {{ position: absolute; top: 22px; left: 50%; width: {note_w}px; height: {note_h}px;
  transform: translateX(-50%) rotate(-1.4deg); background: {paper};
  box-shadow: 0 10px 18px rgba(48,35,24,.45), 0 2px 3px rgba(48,35,24,.35);
  display: flex; align-items: center; justify-content: center; padding: 18px 40px 8px; }}
.note::after {{ content: ''; position: absolute; right: 0; bottom: 0; width: 42px; height: 42px;
  background: linear-gradient(135deg, transparent 50%, rgba(0,0,0,.08) 50%); }}
.pin {{ position: absolute; top: -12px; left: 50%; width: 34px; height: 34px; margin-left: -17px; border-radius: 50%;
  background: radial-gradient(circle at 35% 30%, #ff8a80, #d32f2f 55%, #8e1b1b); box-shadow: 0 4px 5px rgba(0,0,0,.45); }}
h1 {{ font-family: Hand, cursive; font-weight: 400; color: #3B372F; font-size: {font}px; line-height: 1.02;
  text-align: center; letter-spacing: .3px; text-wrap: balance; }}
.shot {{ position: absolute; top: {band + 18}px; left: 50%; transform: translateX(-50%); width: {shot_w}px;
  border-radius: {radius}px; overflow: hidden; box-shadow: 0 24px 50px rgba(20,12,4,.55), 0 4px 10px rgba(20,12,4,.4); }}
.shot img {{ display: block; width: 100%; }}
</style></head><body><div class="shade"></div>
<div class="note"><div class="pin"></div><h1>{html.escape(words)}</h1></div>
<div class="shot"><img src="{shot.as_uri()}"></div>
</body></html>"""


# The feature graphic's words: the name, then what it is.
BANNER = {
    'en': ('Sticky Wall', 'Sticky notes, lists and reminders on a real wall'),
    'vi': ('Sticky Wall', 'Giấy nhớ, việc cần làm và nhắc việc trên tường thật'),
}


def banner(lang: str) -> str:
    """The 1024x500 feature graphic: a real wall beside a pinned note."""
    name, line = BANNER[lang]
    shot = (KIT / 'screenshots' / 'desktop' / lang / '01_wall_home.webp').as_uri()
    wordmark = (KIT / 'brand' / 'fonts' / 'Pacifico-Regular.ttf').as_uri()
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>
@font-face {{ font-family: Hand; src: url('{FONT}'); }}
@font-face {{ font-family: Mark; src: url('{wordmark}'); }}
* {{ box-sizing: border-box; margin: 0; }}
html, body {{ width: 1024px; height: 500px; overflow: hidden; }}
body {{ background: #8a6238 url('{CORK}') repeat; background-size: 420px; position: relative; }}
.shot {{ position: absolute; right: -150px; top: 46px; width: 760px; transform: rotate(-3deg);
  border-radius: 18px; overflow: hidden; box-shadow: 0 20px 40px rgba(20,12,4,.55); }}
.shot img {{ display: block; width: 100%; }}
.note {{ position: absolute; left: 42px; top: 70px; width: 400px; height: 360px; background: #FFF59D;
  transform: rotate(-2.5deg); box-shadow: 0 14px 22px rgba(48,35,24,.5); padding: 54px 34px 30px; }}
.pin {{ position: absolute; top: -12px; left: 50%; width: 34px; height: 34px; margin-left: -17px; border-radius: 50%;
  background: radial-gradient(circle at 35% 30%, #ff8a80, #d32f2f 55%, #8e1b1b); box-shadow: 0 4px 5px rgba(0,0,0,.45); }}
h1 {{ font-family: Mark, cursive; font-weight: 400; color: #3B372F; font-size: 60px; line-height: 1.1; }}
p {{ font-family: Hand, cursive; color: #3B372F; font-size: 38px; line-height: 1.12; margin-top: 18px; text-wrap: balance; }}
</style></head><body>
<div class="shot"><img src="{shot}"></div>
<div class="note"><div class="pin"></div><h1>{html.escape(name)}</h1><p>{html.escape(line)}</p></div>
</body></html>"""


def render(browser: str, page_html: str, out: pathlib.Path, width: int,
           height: int) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        src = pathlib.Path(tmp) / 'slide.html'
        src.write_text(page_html, encoding='utf-8')
        subprocess.run(
            [browser, '--headless=new', '--disable-gpu', '--hide-scrollbars',
             '--force-device-scale-factor=1', '--allow-file-access-from-files',
             f'--window-size={width},{height}', f'--screenshot={out}',
             '--virtual-time-budget=4000', src.as_uri()],
            check=True, capture_output=True)


def main() -> None:
    browser = next((b for b in BROWSERS if pathlib.Path(b).exists()), None)
    if browser is None:
        sys.exit('Edge or Chrome is needed to render the slides.')
    for lang, idx in (('en', 1), ('vi', 2)):
        phone_dir = OUT / lang / 'phone'
        tablet_dir = OUT / lang / 'tablet'
        for d in (phone_dir, tablet_dir):
            shutil.rmtree(d, ignore_errors=True)
            d.mkdir(parents=True)
        for n, row in enumerate(PHONE, 1):
            shot = KIT / 'screenshots' / 'phone' / lang / f'{row[0]}.webp'
            render(browser, page(1080, 1920, shot, row[idx], row[3], False),
                   phone_dir / f'{n}.png', 1080, 1920)
        for n, row in enumerate(TABLET, 1):
            shot = KIT / 'screenshots' / 'desktop' / lang / f'{row[0]}.webp'
            render(browser, page(1920, 1080, shot, row[idx], row[3], True),
                   tablet_dir / f'{n}.png', 1920, 1080)
        render(browser, banner(lang), OUT / lang / 'feature_graphic.png',
               1024, 500)
        print(f'{lang}: {len(PHONE)} phone, {len(TABLET)} tablet slides')


if __name__ == '__main__':
    main()
