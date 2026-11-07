"""Google Play Console from the command line (Google Play Developer API).

The service-account key is read from the PLAY_KEY environment variable, or
from ~/.secrets/play-publisher.json. It never belongs in this repo.

    python tool/play.py check [package]       read-only report of the listing,
                                              images, tracks, testers, products
    python tool/play.py upload <aab> <track>  [--name NAME] [--notes FILE]
                                              upload a bundle to a testing track
                                              as a draft release
    python tool/play.py complete <track> <versionCode>
                                              roll a draft out: the release with
                                              that code becomes "completed" (sent
                                              for review, then live on the track)
    python tool/play.py codes                 print the highest versionCode ever
                                              uploaded (the next must be higher)

Tracks: internal, alpha (= closed testing), beta (= open testing). The key
has no production rights, on purpose.

Every write happens inside an "edit" that is committed only at the end; a
failed run leaves the console untouched.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

DEFAULT_PACKAGE = 'com.apps.winka.stickywall'
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']
IMAGE_TYPES = [
    'icon',
    'featureGraphic',
    'phoneScreenshots',
    'sevenInchScreenshots',
    'tenInchScreenshots',
]


def service():
    key = os.environ.get('PLAY_KEY') or str(
        Path.home() / '.secrets' / 'play-publisher.json'
    )
    if not Path(key).is_file():
        sys.exit(f'No key at {key}. Set PLAY_KEY to the service-account JSON.')
    creds = service_account.Credentials.from_service_account_file(
        key, scopes=SCOPES
    )
    return build('androidpublisher', 'v3', credentials=creds, cache_discovery=False)


def _err(e: HttpError) -> str:
    try:
        return json.loads(e.content)['error']['message']
    except Exception:
        return str(e)


def check(package: str) -> None:
    api = service()
    edits = api.edits()
    try:
        edit = edits.insert(packageName=package, body={}).execute()
    except HttpError as e:
        sys.exit(f'Cannot open {package}: {_err(e)}')
    eid = edit['id']
    try:
        d = edits.details().get(packageName=package, editId=eid).execute()
        print('== Details')
        for k in ('defaultLanguage', 'contactEmail', 'contactPhone', 'contactWebsite'):
            print(f'  {k}: {d.get(k, "-")}')

        listings = edits.listings().list(packageName=package, editId=eid).execute()
        print('\n== Listings')
        langs = []
        for l in listings.get('listings', []):
            langs.append(l['language'])
            print(f"  [{l['language']}]")
            print(f"    title ({len(l.get('title', ''))}): {l.get('title', '')}")
            sd = l.get('shortDescription', '')
            print(f'    short ({len(sd)}): {sd}')
            fd = l.get('fullDescription', '')
            print(f'    full ({len(fd)}): {fd[:70]!r}...')
            if l.get('video'):
                print(f"    video: {l['video']}")

        print('\n== Images')
        for lang in langs:
            row = []
            for t in IMAGE_TYPES:
                r = edits.images().list(
                    packageName=package, editId=eid, language=lang, imageType=t
                ).execute()
                row.append(f"{t}={len(r.get('images', []))}")
            print(f'  [{lang}] ' + ', '.join(row))

        print('\n== Tracks')
        tracks = edits.tracks().list(packageName=package, editId=eid).execute()
        for t in tracks.get('tracks', []):
            print(f"  {t['track']}:")
            for r in t.get('releases', []) or [{}]:
                if not r:
                    print('    (no release)')
                    continue
                notes = ', '.join(n['language'] for n in r.get('releaseNotes', []))
                print(
                    f"    {r.get('status')} name={r.get('name', '-')!r} "
                    f"codes={r.get('versionCodes', [])} notes=[{notes}]"
                )
            try:
                testers = edits.testers().get(
                    packageName=package, editId=eid, track=t['track']
                ).execute()
                groups = testers.get('googleGroups', [])
                if groups:
                    print(f'    tester groups: {groups}')
            except HttpError:
                pass

        print('\n== Bundles uploaded')
        b = edits.bundles().list(packageName=package, editId=eid).execute()
        codes = sorted(x['versionCode'] for x in b.get('bundles', []))
        print(f'  versionCodes: {codes or "-"}')
    finally:
        edits.delete(packageName=package, editId=eid).execute()

    print('\n== One-time products')
    try:
        r = api.monetization().onetimeproducts().list(packageName=package).execute()
        for p in r.get('oneTimeProducts', []):
            names = {x['languageCode']: x.get('title') for x in p.get('listings', [])}
            print(f"  {p['productId']}: titles={names}")
            for o in p.get('purchaseOptions', []):
                state = o.get('state', '-')
                print(f"    option {o.get('purchaseOptionId')}: {state}")
    except (HttpError, AttributeError) as e:
        msg = _err(e) if isinstance(e, HttpError) else 'not in this client'
        print(f'  (new API unavailable: {msg}); trying in-app products')
        try:
            r = api.inappproducts().list(packageName=package).execute()
            for p in r.get('inappproduct', []):
                langs = ', '.join(sorted(p.get('listings', {})))
                print(f"  {p['sku']}: {p.get('status')} [{langs}] {p.get('defaultPrice')}")
        except HttpError as e2:
            print(f'  cannot read products: {_err(e2)}')


def upload(package: str, aab: str, track: str, name: str | None, notes: str | None) -> None:
    api = service()
    edits = api.edits()
    eid = edits.insert(packageName=package, body={}).execute()['id']
    try:
        media = MediaFileUpload(aab, mimetype='application/octet-stream', resumable=True)
        bundle = edits.bundles().upload(
            packageName=package, editId=eid, media_body=media
        ).execute()
        code = bundle['versionCode']
        print(f'Uploaded versionCode {code}')
        release = {'versionCodes': [str(code)], 'status': 'draft'}
        if name:
            release['name'] = name
        if notes:
            release['releaseNotes'] = json.loads(Path(notes).read_text(encoding='utf-8'))
        edits.tracks().update(
            packageName=package,
            editId=eid,
            track=track,
            body={'track': track, 'releases': [release]},
        ).execute()
        edits.commit(packageName=package, editId=eid).execute()
        print(f'Draft release on {track}. Review and roll it out in Play Console.')
    except Exception:
        edits.delete(packageName=package, editId=eid).execute()
        raise


def complete(package: str, track: str, code: str) -> None:
    """Rolls the release holding [code] out to everyone on [track].

    Older releases on the track are dropped from it: the new one replaces
    them, as rolling out in Play Console would.
    """
    api = service()
    edits = api.edits()
    eid = edits.insert(packageName=package, body={}).execute()['id']
    try:
        t = edits.tracks().get(packageName=package, editId=eid, track=track).execute()
        before = [(r.get('versionCodes'), r.get('status')) for r in t.get('releases', [])]
        print(f'{track} before: {before}')
        keep = [r for r in t.get('releases', []) if code in r.get('versionCodes', [])]
        if not keep:
            sys.exit(f'No release with versionCode {code} on {track}.')
        for r in keep:
            r['status'] = 'completed'
            r.pop('userFraction', None)
        t['releases'] = keep
        edits.tracks().update(packageName=package, editId=eid, track=track, body=t).execute()
        edits.commit(packageName=package, editId=eid).execute()
    except BaseException:
        try:
            edits.delete(packageName=package, editId=eid).execute()
        except HttpError:
            pass
        raise
    eid = edits.insert(packageName=package, body={}).execute()['id']
    t = edits.tracks().get(packageName=package, editId=eid, track=track).execute()
    print(f"{track} after: {[(r.get('versionCodes'), r.get('status'), r.get('name')) for r in t.get('releases', [])]}")
    edits.delete(packageName=package, editId=eid).execute()


def codes(package: str) -> None:
    """Prints the highest versionCode Play has ever seen for the app."""
    api = service()
    edits = api.edits()
    eid = edits.insert(packageName=package, body={}).execute()['id']
    try:
        b = edits.bundles().list(packageName=package, editId=eid).execute()
        seen = [x['versionCode'] for x in b.get('bundles', [])]
        print(max(seen) if seen else 0)
    finally:
        edits.delete(packageName=package, editId=eid).execute()


def main() -> None:
    # Listings are Vietnamese too; a Windows console defaults to cp1252.
    sys.stdout.reconfigure(encoding='utf-8')
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    c = sub.add_parser('check')
    c.add_argument('package', nargs='?', default=DEFAULT_PACKAGE)
    u = sub.add_parser('upload')
    u.add_argument('aab')
    u.add_argument('track')
    u.add_argument('--package', default=DEFAULT_PACKAGE)
    u.add_argument('--name')
    u.add_argument('--notes', help='JSON list of {"language", "text"}')
    r = sub.add_parser('complete')
    r.add_argument('track')
    r.add_argument('code')
    r.add_argument('--package', default=DEFAULT_PACKAGE)
    k = sub.add_parser('codes')
    k.add_argument('--package', default=DEFAULT_PACKAGE)
    a = p.parse_args()
    if a.cmd == 'check':
        check(a.package)
    elif a.cmd == 'complete':
        complete(a.package, a.track, a.code)
    elif a.cmd == 'codes':
        codes(a.package)
    else:
        upload(a.package, a.aab, a.track, a.name, a.notes)


if __name__ == '__main__':
    main()
