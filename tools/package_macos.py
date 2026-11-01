"""Build the local Apple Silicon playtest ZIP. Run with Python 3 on macOS."""
from pathlib import Path
import hashlib
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / '.tools/Godot.app/Contents/MacOS/Godot'
TEMPLATES = ROOT / '.tools/export_templates/4.7.2.stable'
NAME = 'Frostmere-0.1.0-macOS-AppleSilicon'
PACKAGE = ROOT / 'dist' / NAME


def run(*args):
    subprocess.run([str(a) for a in args], cwd=ROOT, check=True)


def prepare_template():
    target = TEMPLATES / 'macos-arm64.zip'
    if target.exists():
        return
    source = TEMPLATES / 'macos.zip'
    if not source.exists():
        raise SystemExit('Extract templates/macos.zip from the official Godot 4.7.2 export templates into ' + str(TEMPLATES))
    with tempfile.TemporaryDirectory(prefix='frostmere-template-') as folder:
        pending = Path(folder) / 'macos-arm64.zip'
        with zipfile.ZipFile(source) as src, zipfile.ZipFile(pending, 'w', zipfile.ZIP_DEFLATED) as dst:
            for entry in src.infolist():
                data = src.read(entry)
                if entry.filename.endswith('.universal'):
                    fat, thin = Path(folder) / 'universal', Path(folder) / 'arm64'
                    fat.write_bytes(data)
                    run('lipo', fat, '-thin', 'arm64', '-output', thin)
                    data = thin.read_bytes()
                    entry.filename = entry.filename.replace('.universal', '.arm64')
                dst.writestr(entry, data)
        shutil.copyfile(pending, target)


def main():
    prepare_template()
    PACKAGE.mkdir(parents=True, exist_ok=True)
    app = PACKAGE / 'Frostmere.app'
    log = ROOT / 'dist/package-export.log'
    with log.open('w') as output:
        subprocess.run([str(ENGINE), '--headless', '--path', str(ROOT), '--export-release',
                        'macOS Playtest', str(app)], cwd=ROOT, stdout=output,
                       stderr=subprocess.STDOUT, check=True)
    if 'ERROR:' in log.read_text():
        raise SystemExit('Export reported errors; inspect ' + str(log))
    run('codesign', '--verify', '--deep', '--strict', app)
    shutil.copyfile(ROOT / 'docs/MAC_PLAYTEST.txt', PACKAGE / 'READ ME.txt')
    run(ENGINE, '--headless', '--path', ROOT, '--script', 'tools/export_notices.gd',
        '--', PACKAGE / 'THIRD-PARTY-NOTICES.txt')
    archive = ROOT / 'dist' / (NAME + '.zip')
    run('ditto', '-c', '-k', '--keepParent', '--norsrc', PACKAGE, archive)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    archive.with_suffix('.zip.sha256').write_text(digest + '  ' + archive.name + '\n')
    print('PACKAGE_CREATED', archive, archive.stat().st_size, 'bytes')


if __name__ == '__main__':
    main()
