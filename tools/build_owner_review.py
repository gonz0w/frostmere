"""Build a local entry page for existing native owner-review captures."""
from pathlib import Path
import html
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'build/owner-review'


def main():
    galleries = [('building', 'Buildings and interiors'),
                 ('landscape', 'Towns and landscapes'),
                 ('presentation', 'Opening, cameras, dialogue and audio')]
    cards = []
    for name, title in galleries:
        folder = ROOT / 'build' / f'{name}-review'
        rows = json.loads((folder/'manifest.json').read_text())
        assert (folder/'index.html').is_file()
        for row in rows:
            image = folder / ('after' if name == 'landscape' else '') / row['file']
            assert image.is_file(), image
        cards.append(f'<li><a href="../{name}-review/index.html">{title}</a> — {len(rows)} current views</li>')
    for name in ['aeralis', 'crucible']:
        assert (ROOT/f'build/building-review/{name}-atmosphere.jpg').is_file()
    assert (ROOT/'build/presentation-review/intro-engine-mix.wav').is_file()
    revision = subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD'], cwd=ROOT, text=True).strip()
    OUT.mkdir(parents=True, exist_ok=True)
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Frostmere · Owner presentation review</title><style>body{max-width:960px;margin:3rem auto;padding:0 1.5rem;background:#111c23;color:#ebe4d7;font:18px/1.6 system-ui}a{color:#edbd72}h1{font-family:Georgia}li{margin:1rem 0}img{width:100%;border-radius:8px}section{margin:2rem 0}small{color:#bcc7ce}audio{width:100%}</style>
<h1>Frostmere · Presentation review</h1>
<p>Start with the galleries, then check movement and audio transitions in native play. Captures use isolated profiles; no player saves are changed.</p>
<ul>__CARDS__</ul>
<p>The landscape “Before” images are retained historical comparisons, not new captures. Current views are under “After”. The galleries freeze actors for inspection and do not qualify performance or combat balance.</p>
<section><h2>Aeralis · mystical sky</h2><img src="../building-review/aeralis-atmosphere.jpg" alt="Aeralis celestial sky"></section>
<section><h2>Crucible · burning cavern roof</h2><img src="../building-review/crucible-atmosphere.jpg" alt="Crucible cavern roof"></section>
<section><h2>Native opening mix</h2><audio controls preload="none" src="../presentation-review/intro-engine-mix.wav"></audio><p>The presentation gallery also provides all nine scores and 32 interaction/combat cues. Playback starts only when you choose it.</p></section>
<p><a href="../../docs/PRESENTATION_CHECKLIST.md">Review procedure and regeneration instructions</a> · <a href="https://github.com/gonz0w/frostmere/issues/7">Record approval or requested changes in #7</a></p>
<small>Page built against checkout __REV__. This identifies the page build, not capture provenance; see the issue for the actual capture run and validation. No release or owner sign-off is implied.</small></html>'''
    (OUT/'index.html').write_text(page.replace('__CARDS__', ''.join(cards)).replace('__REV__', html.escape(revision)))
    print('OWNER_REVIEW_PAGE_COMPLETE')


if __name__ == '__main__':
    main()
