"""Build an experimental Windows x64 ZIP from tracked runtime files; Python 3.11+."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE_SHA256 = 'f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011'
TEMPLATE_URL = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
RUNTIME = {'assets', 'data', 'scenes', 'scripts', 'shaders'}


def digest(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def verify_templates(path):
    if digest(path) != TEMPLATE_SHA256:
        raise ValueError('Godot template checksum mismatch')


def verify_pe(path):
    data = Path(path).read_bytes()
    offset = int.from_bytes(data[60:64], 'little')
    if (data[:2] != b'MZ' or data[offset:offset+4] != b'PE\0\0'
            or data[offset+4:offset+6] != b'\x64\x86'):
        raise ValueError('Expected a Windows x86_64 PE binary')


def run(engine, stage, logs, name, *flags):
    result = subprocess.run([engine, '--headless', '--path', str(stage), *map(str, flags)],
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            timeout=300, text=True, encoding='utf-8', errors='replace')
    output = result.stdout
    (logs / (name + '.log')).write_text(output.replace(str(ROOT), '<project>').replace(str(Path.home()), '<home>'), encoding='utf-8')
    if result.returncode or re.search(r'SCRIPT ERROR:|ERROR:', output):
        raise RuntimeError(f'{name} failed; inspect {logs / (name + ".log")}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--templates', required=True, type=Path, help='Official matching export_templates.tpz')
    args = parser.parse_args()
    engine = shutil.which(args.godot) or str(Path(args.godot).resolve())
    version = subprocess.check_output([engine, '--version'], text=True, encoding='utf-8', timeout=15).strip()
    if not re.fullmatch(r'4\.7\.2\.stable(?:\.[A-Za-z0-9_-]+)*', version):
        raise ValueError('Godot 4.7.2 stable is required')
    verify_templates(args.templates)
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True, encoding='utf-8').strip()
    # Refuse mislabeled artifacts: commit source and build tooling before packaging.
    if subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'], cwd=ROOT):
        raise ValueError('Commit tracked changes before packaging')
    name = 'Frostmere-Windows-x64-' + revision[:12]
    dist = ROOT / 'dist'
    dist.mkdir(exist_ok=True)
    archive = dist / (name + '.zip')
    if archive.exists():
        raise FileExistsError(f'Package already exists: {archive}')
    logs = ROOT / 'build/windows' / revision[:12]
    logs.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='frostmere-windows-', dir=logs) as temp:
        stage = Path(temp) / 'project'
        package = Path(temp) / name
        stage.mkdir()
        package.mkdir()
        tracked = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
        for relative in filter(None, tracked):
            path = Path(relative)
            if path.parts[0] in RUNTIME or relative in {'project.godot', 'export_presets.cfg'}:
                target = stage / path
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / path, target)
        templates = stage / '.tools/export_templates/4.7.2.stable'
        templates.mkdir(parents=True)
        with zipfile.ZipFile(args.templates) as source:
            for filename in ('windows_release_x86_64.exe', 'windows_debug_x86_64.exe'):
                (templates / filename).write_bytes(source.read('templates/' + filename))
        run(engine, stage, logs, 'import', '--editor', '--import', '--quit')
        run(engine, stage, logs, 'export', '--export-release', 'Windows Playtest', package / 'Frostmere.exe')
        verify_pe(package / 'Frostmere.exe')
        verify_pe(package / 'Frostmere.console.exe')
        if not (package / 'Frostmere.pck').is_file():
            raise RuntimeError('Missing game PCK')
        # Generate component notices from the matching engine without loading game saves.
        run(engine, ROOT, logs, 'notices', '--script', ROOT / 'tools/export_notices.gd', '--', package / 'GODOT-NOTICES.txt')
        shutil.copyfile(ROOT / 'LICENSE', package / 'LICENSE.txt')
        shutil.copyfile(ROOT / 'docs/WINDOWS_PLAYTEST.txt', package / 'READ ME.txt')
        provenance = {'source': 'https://github.com/gonz0w/frostmere', 'revision': revision,
                      'engine': version, 'templates_url': TEMPLATE_URL,
                      'templates_sha256': TEMPLATE_SHA256, 'target': 'Windows x86_64',
                      'status': 'Experimental tester build; native qualification pending #26',
                      'files': {p.name: digest(p) for p in sorted(package.iterdir())}}
        (package / 'BUILD.json').write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8')
        with zipfile.ZipFile(archive, 'x', zipfile.ZIP_DEFLATED) as output:
            for path in sorted(package.iterdir()):
                output.write(path, name + '/' + path.name)
    archive.with_suffix('.zip.sha256').write_text(digest(archive) + '  ' + archive.name + '\n', encoding='utf-8')
    print('WINDOWS_PACKAGE_CREATED', archive)


if __name__ == '__main__':
    main()
