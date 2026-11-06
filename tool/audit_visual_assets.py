"""Read-only artwork checks and review sheets; never rewrites shipped assets."""
from collections import Counter
from pathlib import Path
import csv
import hashlib
import json
import re

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/visual_polish/audit'


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((ROOT / 'docs/design/STICKY_VISUAL_ASSET_MANIFEST.json').read_text(encoding='utf-8'))['assets']
    dart = (ROOT / 'lib/widgets/sticker_assets.g.dart').read_text(encoding='utf-8')
    rows = []
    for asset in manifest:
        path = ROOT / asset['path']
        data = path.read_bytes()
        image = Image.open(path).convert('RGBA')
        alpha = image.getchannel('A')
        errors = []
        if image.size != (asset['width'], asset['height']): errors.append('dimensions')
        if len(data) != asset['bytes']: errors.append('bytes')
        if hashlib.sha256(data).hexdigest() != asset['sha256']: errors.append('sha256')
        if alpha.getextrema()[0] != 0: errors.append('no transparent pixel')
        if alpha.getextrema()[1] == 0: errors.append('empty')
        if max(image.size) > 360: errors.append('oversized')
        if asset['id'] not in dart or asset['path'] not in dart: errors.append('not integrated')
        if not asset.get('source') or not asset.get('license'): errors.append('missing provenance')
        rows.append(dict(id=asset['id'], size=image.size, bytes=len(data),
                         alpha=alpha.getextrema(), errors=errors,
                         sha256=hashlib.sha256(data).hexdigest()))
    duplicates = [h for h, count in Counter(r['sha256'] for r in rows).items() if count > 1]
    # All 197 assets on alternating light/dark paper, numbered by manifest order.
    for start in range(0, len(manifest), 60):
        entries = manifest[start:start + 60]
        sheet = Image.new('RGB', (1200, ((len(entries)+7)//8)*150), '#f9f2e3')
        draw = ImageDraw.Draw(sheet)
        for i, asset in enumerate(entries):
            x, y = (i % 8)*150, (i//8)*150
            draw.rectangle((x,y,x+149,y+149),fill='#38352e' if i%2 else '#f9f2e3')
            image=Image.open(ROOT/asset['path']).convert('RGBA')
            image.thumbnail((125,115))
            sheet.paste(image,(x+(150-image.width)//2,y+(120-image.height)//2),image)
            draw.text((x+5,y+125),f'{start+i+1:03} '+asset['id'].removeprefix('art_')[:19],
                      fill='#fff9e6' if i%2 else '#37342e')
        sheet.save(OUT/f'art_{start//60+1}.jpg',quality=92)
    icons=[]
    for path in sorted((ROOT/'lib').rglob('*.dart')):
        if path.name.startswith('app_localizations'): continue
        for number, line in enumerate(path.read_text(encoding='utf-8').splitlines(),1):
            for name in re.findall(r'\b(?:Icons|AppIcons)\.([a-zA-Z0-9_]+)',line):
                icons.append([path.relative_to(ROOT).as_posix(), number, name, line.strip()])
    with (OUT/'icon_inventory.csv').open('w',encoding='utf-8-sig',newline='') as stream:
        writer=csv.writer(stream);writer.writerow(['File','Line','Glyph/role','Context']);writer.writerows(icons)
    report=dict(audited=len(rows),free=sum(a['free'] for a in manifest),
                total_bytes=sum(r['bytes'] for r in rows),byte_identical_duplicates=duplicates,
                icon_occurrences=len(icons),unique_icon_names=len(set(i[2] for i in icons)),
                changed_assets=0,checks=rows,
                limits='Automated checks cannot prove copyright clearance or detect all visual near-duplicates/halos. Review contact sheets visually.')
    (OUT/'asset_audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k!='checks'}))
    assert not duplicates and not any(r['errors'] for r in rows)


if __name__=='__main__': main()
