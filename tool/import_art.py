"""Imports artwork sheets from the image-generation batches into the app.

Each batch folder holds sheets drawn on a flat #00FF00 background plus a
manifest.json (sheet, row, col, id, en, vi, category). This script:

- cuts every cell out of its sheet, keys the green out to real alpha (with
  the green spill on the anti-aliased edge taken back out), trims it, and
  saves it as a lossy-with-alpha WebP under assets/stickers/;
- rewrites lib/widgets/sticker_assets.g.dart (the sticker list the app
  reads) and docs/design/STICKY_VISUAL_ASSET_MANIFEST.json (path, size,
  bytes, sha256, batch, category, free/Pro, provenance) from every batch
  imported so far;
- writes one contact sheet per category under
  docs/design/STICKY_VISUAL_CONTACT_SHEETS/.

Run from the repo root:

    python tool/import_art.py <batch-name> <batch-folder> [<batch-name> <batch-folder> ...]

Batches already in the manifest are kept; naming one again re-imports it.
Needs Pillow.
"""
import hashlib
import json
import os
import sys

from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, 'assets', 'stickers')
DART = os.path.join(ROOT, 'lib', 'widgets', 'sticker_assets.g.dart')
MANIFEST = os.path.join(ROOT, 'docs', 'design', 'STICKY_VISUAL_ASSET_MANIFEST.json')
SHEETS = os.path.join(ROOT, 'docs', 'design', 'STICKY_VISUAL_CONTACT_SHEETS')

# Which shelf of the sticker picker each category goes on, and whether it
# comes with the free app.
SHELVES = {
    'feelings': ('feelings', True),
    'study': ('study', True),
    'home': ('home', True),
    'vietnam': ('vietnam', False),
    'nature': ('nature', False),
    'food': ('food', False),
    'travel': ('travel', False),
    'planner': ('planner', True),
    'tape': ('tapes', False),
}

MAX_EDGE = 360  # px: a sticker is at most ~120 dp wide at 3x


def key_green(im):
    """Real alpha from the flat green ground, and the green spill taken out
    of the anti-aliased rim only: greens inside the art (leaves, mint tape,
    avocado) are left exactly as drawn."""
    im = im.convert('RGBA')
    w, h = im.size
    px = im.load()
    ground = Image.new('L', (w, h), 0)
    gp = ground.load()
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            if g >= 200 and g - max(r, b) >= 90:
                gp[x, y] = 255
    # The rim: within a few pixels of the ground.
    near = ground.filter(ImageFilter.MaxFilter(7)).load()
    for y in range(h):
        for x in range(w):
            if gp[x, y]:
                px[x, y] = (0, 0, 0, 0)
                continue
            if not near[x, y]:
                continue
            r, g, b, _ = px[x, y]
            spill = g - max(r, b)
            if spill <= 10:
                continue
            a = max(0, min(255, int(255 * (1 - (spill - 10) / 120))))
            px[x, y] = (r, max(r, b), b, a)
    return im


def cells(sheet, rows, cols):
    w, h = sheet.size
    for r in range(rows):
        for c in range(cols):
            yield r, c, sheet.crop((c * w // cols, r * h // rows, (c + 1) * w // cols, (r + 1) * h // rows))


def trimmed(im):
    box = im.getbbox()
    if box is None:
        return None
    pad = 4
    box = (max(0, box[0] - pad), max(0, box[1] - pad), min(im.width, box[2] + pad), min(im.height, box[3] + pad))
    im = im.crop(box)
    scale = min(1.0, MAX_EDGE / max(im.size))
    if scale < 1:
        im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
    return im


def main(args):
    pairs = list(zip(args[0::2], args[1::2]))
    os.makedirs(ASSETS, exist_ok=True)
    os.makedirs(SHEETS, exist_ok=True)
    manifest = []
    if os.path.exists(MANIFEST):
        manifest = json.load(open(MANIFEST, encoding='utf-8'))['assets']
    redo = {name for name, _ in pairs}
    manifest = [m for m in manifest if m['batch'] not in redo]

    for batch, folder in pairs:
        entries = json.load(open(os.path.join(folder, 'out', 'manifest.json'), encoding='utf-8'))
        by_sheet = {}
        for e in entries:
            by_sheet.setdefault(e['sheet'], []).append(e)
        for sheet_name, items in by_sheet.items():
            sheet = Image.open(os.path.join(folder, 'out', sheet_name))
            rows = max(e['row'] for e in items) + 1
            cols = max(e['col'] for e in items) + 1
            keyed = key_green(sheet)
            grid = {(r, c): img for r, c, img in cells(keyed, rows, cols)}
            for e in items:
                art = trimmed(grid[(e['row'], e['col'])])
                if art is None:
                    print('empty cell', sheet_name, e['row'], e['col'])
                    continue
                aid = 'art_' + e['id']
                path = os.path.join(ASSETS, aid + '.webp')
                art.save(path, 'WEBP', quality=88, method=6)
                data = open(path, 'rb').read()
                shelf, free = SHELVES[e['category']]
                manifest.append({
                    'id': aid,
                    'path': 'assets/stickers/%s.webp' % aid,
                    'width': art.width,
                    'height': art.height,
                    'format': 'webp (lossy, alpha)',
                    'bytes': len(data),
                    'sha256': hashlib.sha256(data).hexdigest(),
                    'batch': batch,
                    'category': e['category'],
                    'shelf': shelf,
                    'free': free,
                    'en': e['en'],
                    'vi': e['vi'],
                    'source': 'Generated for Sticky Wall with Codex image generation (%s/%s, row %d col %d); '
                              'background keyed out by tool/import_art.py' % (batch, sheet_name, e['row'], e['col']),
                    'license': 'Original artwork made for this app; no third-party material.',
                })

    ids = [m['id'] for m in manifest]
    assert len(ids) == len(set(ids)), 'duplicate ids'
    dupes = {}
    for m in manifest:
        dupes.setdefault(m['sha256'], []).append(m['id'])
    assert all(len(v) == 1 for v in dupes.values()), 'identical files'

    os.makedirs(os.path.dirname(MANIFEST), exist_ok=True)
    json.dump({'version': 1, 'assets': manifest}, open(MANIFEST, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

    def dart_str(s):
        return "'" + s.replace('\\', '\\\\').replace("'", "\\'") + "'"

    lines = [
        '// GENERATED by tool/import_art.py from docs/design/STICKY_VISUAL_ASSET_MANIFEST.json.',
        '// Do not edit by hand.',
        '',
        "part of 'stickers.dart';",
        '',
        '/// Illustrated stickers, drawn for the app and bundled as WebP.',
        'const artStickers = <Sticker>[',
    ]
    for m in manifest:
        lines.append(
            '  Sticker(%s, StickerKind.image, asset: %s, pack: StickerPack.%s, nameEn: %s, nameVi: %s%s, '
            'aspect: %.3f),' % (
                dart_str(m['id']), dart_str(m['path']), m['shelf'], dart_str(m['en']), dart_str(m['vi']),
                ', free: true' if m['free'] else '', m['height'] / m['width'],
            ))
    lines += ['];', '']
    open(DART, 'w', encoding='utf-8', newline='\n').write('\n'.join(lines))

    # One contact sheet per category, on a cork-ish and a dark ground so the
    # alpha edge shows on both.
    cats = {}
    for m in manifest:
        cats.setdefault(m['category'], []).append(m)
    for cat, items in cats.items():
        cell = 200
        cols = 6
        rows = (len(items) + cols - 1) // cols
        out = Image.new('RGB', (cols * cell * 2, rows * cell), (0, 0, 0))
        for half, ground in enumerate([(176, 136, 99), (40, 37, 32)]):
            for i, m in enumerate(items):
                tile = Image.new('RGB', (cell, cell), ground)
                art = Image.open(os.path.join(ROOT, m['path'])).convert('RGBA')
                art.thumbnail((cell - 24, cell - 24))
                tile.paste(art, ((cell - art.width) // 2, (cell - art.height) // 2), art)
                out.paste(tile, (half * cols * cell + (i % cols) * cell, (i // cols) * cell))
        out.save(os.path.join(SHEETS, 'stickers_%s.jpg' % cat), quality=85)

    total = sum(m['bytes'] for m in manifest)
    print('%d assets, %.1f KB in assets/stickers' % (len(manifest), total / 1024))


if __name__ == '__main__':
    main(sys.argv[1:])
