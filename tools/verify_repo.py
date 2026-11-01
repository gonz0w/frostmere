"""Offline source-publication checks; Python 3.11+ standard library only."""
from pathlib import Path
import hashlib
import json
import re
import sys
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
errors = []

def check(ok, message):
    if not ok:
        errors.append(message)


def main():
    check(sys.version_info >= (3, 11), 'Python 3.11+ is required')
    bundle = ROOT / '.agent-temper'
    manifest = {}
    for line in (bundle / 'SHA256SUMS').read_text().splitlines():
        digest, name = line.split('  ', 1)
        check(name not in manifest, f'Duplicate framework path: {name}')
        manifest[name] = digest
        p = bundle / name
        check(p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest() == digest,
              f'Framework hash mismatch: {name}')
    actual = {str(p.relative_to(bundle)) for p in bundle.rglob('*') if p.is_file()}
    check(actual == set(manifest) | {'SOURCE.md', 'SHA256SUMS'},
          'Framework inventory differs from the pinned manifest')
    maintained = ['README.md', 'AGENTS.md', 'PROJECT.md', 'CONTRIBUTING.md',
                  'SECURITY.md', 'THIRD_PARTY_NOTICES.md', 'docs/README.md',
                  'docs/REPOSITORY_MAP.md', 'docs/screenshots/README.md',
                  '.agent-temper/METHOD.md', '.agent-temper/profiles/github.md']
    for name in maintained:
        p = ROOT / name
        if not p.is_file():
            errors.append(f'Missing entry point: {name}')
            continue
        text = p.read_text()
        check(not re.search(r'\{\{[A-Z_]+\}\}', text), f'Unresolved template: {name}')
        for link in re.findall(r'!?\[[^\]]*\]\(([^\s)]+)\)', text):
            if re.match(r'[a-zA-Z][a-zA-Z0-9+.-]*:', link) or link.startswith('#'):
                continue
            target = unquote(link.split('#')[0])
            check((p.parent / target).exists(), f'Broken local link in {name}: {target}')
    check('Copyright (c) 2026, gonz0w' in (ROOT / 'LICENSE').read_text(),
          'Unexpected project copyright')
    for p in (ROOT / 'data').glob('*.json'):
        try:
            json.loads(p.read_text())
        except ValueError as exc:
            errors.append(f'Invalid JSON {p.name}: {exc}')
    ignored = {'.git', '.godot', '.tools', 'build', 'dist', '__pycache__', 'export_templates'}
    # File-name and high-signal text scan; not a claim of exhaustive secret detection.
    sensitive = re.compile(r'(?m)(?:-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|'
                           r'gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|'
                           r'sk-proj-[A-Za-z0-9_-]{30,}|AKIA[A-Z0-9]{16})')
    for p in ROOT.rglob('*'):
        rel = p.relative_to(ROOT)
        if any(part in ignored for part in rel.parts) or not p.is_file():
            continue
        check(not p.is_symlink(), f'Unexpected publication symlink: {rel}')
        check(p.stat().st_size < 50 * 1024 * 1024, f'Oversized source asset: {rel}')
        check(not (p.name == '.env' or p.suffix in {'.pem', '.key'}),
              f'Private configuration file in source: {rel}')
        if p.suffix in {'.md', '.txt', '.gd', '.py', '.json', '.cfg', '.godot', '.yml', '.toml'}:
            text = p.read_text(errors='replace')
            check(not sensitive.search(text), f'Possible credential in {rel}')
            check(not re.search(r'/(?:Users|home)/[A-Za-z0-9_.-]+/', text),
                  f'Personal absolute path in {rel}')
    if errors:
        for error in errors:
            print('FAIL:', error)
        return 1
    print(f'REPOSITORY_CHECKS_PASSED framework_files={len(manifest)} entrypoints={len(maintained)}')
    print('Scope: source hygiene, framework hashes/inventory, selected links and data syntax; not runtime or exhaustive security review.')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
