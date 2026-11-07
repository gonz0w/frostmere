"""Verify/install pinned standard Godot CLI binaries and audit resource spelling."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = json.loads((ROOT / 'tools/toolchain.json').read_text(encoding='utf-8'))


def verify_archive(path, expected):
    with Path(path).open('rb') as stream:
        actual = hashlib.file_digest(stream, 'sha256').hexdigest()
    if actual != expected:
        raise ValueError('Archive checksum mismatch; discard it and obtain the pinned official artifact')


def verify_version(value):
    pattern = re.escape(MANIFEST['version']) + r'\.stable\.official\.[A-Za-z0-9]+'
    if not re.fullmatch(pattern, value.strip()):
        raise ValueError('Expected pinned standard official Godot version ' + MANIFEST['version'])


def case_errors(paths, sources):
    errors, names = [], {}
    for path in paths:
        key = path.casefold()
        if key in names and names[key] != path:
            errors.append('Case collision: ' + names[key] + ' / ' + path)
        names[key] = path
    exact = set(paths)
    for source, text in sources.items():
        for path in re.findall(r'["\']res://([^"\'\n]+)["\']', text):
            # Complete literal file references only; computed paths need engine tests.
            if not path.startswith('build/') and Path(path).suffix and '*' not in path and '%' not in path and path not in exact:
                errors.append(f'{source}: missing or incorrectly cased resource {path}')
    return errors


def audit():
    paths = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode('utf-8').split('\0')
    paths = list(filter(None, paths))
    sources = {p: (ROOT / p).read_text(encoding='utf-8') for p in paths
               if (p.startswith(('scripts/', 'scenes/', 'shaders/')) and Path(p).suffix in {'.gd', '.tscn', '.tres', '.gdshader'}) or p == 'project.godot'}
    errors = case_errors(paths, sources)
    if errors:
        raise ValueError('\n'.join(errors))
    print(f'RESOURCE_CASE_AUDIT_PASSED files={len(paths)} sources={len(sources)}')


def install(platform, archive=None):
    entry = MANIFEST['artifacts'][platform]
    target = ROOT / '.tools/pinned' / platform
    target.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='download-', dir=target) as temp:
        source = Path(archive).resolve() if archive else Path(temp) / 'engine.zip'
        if archive is None:
            with urllib.request.urlopen(entry['url'], timeout=120) as response, source.open('wb') as output:
                shutil.copyfileobj(response, output)
        verify_archive(source, entry['sha256'])
        with zipfile.ZipFile(source) as zipped:
            names = entry['executables']
            if platform == 'macos':
                names = [n for n in zipped.namelist() if n.startswith('Godot.app/') and not n.endswith('/')]
            for name in names:
                if '..' in Path(name).parts or Path(name).is_absolute():
                    raise ValueError('Unsafe archive member')
                dest = target / name
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(zipped.read(name))
                if name in entry['executables']:
                    dest.chmod(0o755)
    engine = target / entry['executables'][0]
    verify_version(subprocess.check_output([str(engine), '--version'], text=True, encoding='utf-8', timeout=15))
    return engine


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--install', choices=['macos', 'windows', 'linux'])
    parser.add_argument('--archive', type=Path, help='Optional already downloaded matching engine archive')
    parser.add_argument('--verify-templates', type=Path)
    parser.add_argument('--audit', action='store_true')
    parser.add_argument('--import-check', action='store_true', help='Bounded headless import after install')
    args = parser.parse_args()
    if args.import_check and not args.install:
        parser.error('--import-check requires --install')
    if args.archive and not args.install:
        parser.error('--archive requires --install')
    if not (args.install or args.verify_templates or args.audit):
        parser.error('Choose --install, --verify-templates or --audit')
    if args.audit:
        audit()
    if args.verify_templates:
        verify_archive(args.verify_templates, MANIFEST['artifacts']['templates']['sha256'])
        print('TEMPLATES_VERIFIED')
    if args.install:
        engine = install(args.install, args.archive)
        print('ENGINE_VERIFIED', engine)
        if args.import_check:
            from run_headless import run_check
            result = run_check('import', [str(engine), '--headless', '--path', str(ROOT), '--editor', '--import', '--quit'],
                               ROOT / 'build/toolchain/import.log', 180)
            if not result['passed']:
                raise RuntimeError('Clean import failed; inspect build/toolchain/import.log')
            print('CLEAN_IMPORT_PASSED')


if __name__ == '__main__':
    main()
