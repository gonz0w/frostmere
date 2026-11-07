"""Build verified development archives from tracked runtime files; Python 3.11+."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import tarfile
import sys
from toolchain import configure_console
from play import checked_engine
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TOOLCHAIN = json.loads((ROOT / 'tools/toolchain.json').read_text(encoding='utf-8'))
TEMPLATE_SHA256 = TOOLCHAIN['artifacts']['templates']['sha256']
TEMPLATE_URL = TOOLCHAIN['artifacts']['templates']['url']
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
    failed = False
    try:
        result = subprocess.run([engine, '--headless', '--path', str(stage), *map(str, flags)],
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                timeout=300, text=True, encoding='utf-8', errors='replace')
        output = result.stdout
        failed = result.returncode != 0
    except subprocess.TimeoutExpired as exc:
        output = exc.stdout or b''
        if isinstance(output, bytes):
            output = output.decode('utf-8', errors='replace')
        output += '\nERROR: package step timed out\n'
        failed = True
    except OSError as exc:
        output = 'ERROR: could not start engine: ' + str(exc)
        failed = True
    (logs / (name + '.log')).write_text(output.replace(str(ROOT), '<project>').replace(str(Path.home()), '<home>'), encoding='utf-8')
    if failed or re.search(r'SCRIPT ERROR:|ERROR:', output):
        raise RuntimeError(f'{name} failed; inspect {logs / (name + ".log")}')


def verify_elf(path):
    data = Path(path).read_bytes()[:64]
    if data[:6] != b'\x7fELF\x02\x01' or data[18:20] != b'\x3e\x00':
        raise ValueError('Expected a Linux x86_64 ELF binary')


def verify_bundle(archive, name, target):
    if target == 'linux':
        with tarfile.open(archive, 'r:gz') as source:
            members = [m for m in source.getmembers() if not m.isdir()]
            if any(not m.isfile() for m in members):
                raise ValueError('Unexpected archive link or special file')
            files = {m.name: source.extractfile(m).read() for m in members}
            if not source.getmember(name + '/Frostmere.x86_64').mode & 0o111:
                raise ValueError('Linux binary is not executable')
    else:
        with zipfile.ZipFile(archive) as source:
            files = {n: source.read(n) for n in source.namelist() if not n.endswith('/')}
            if target == 'macos':
                binaries = [i for i in source.infolist() if '/Contents/MacOS/' in i.filename and not i.is_dir()]
                if not binaries or any(not (i.external_attr >> 16) & 0o111 for i in binaries):
                    raise ValueError('macOS archive binary is not executable')
    manifest = json.loads(files.pop(name + '/BUILD.json'))
    expected = {name + '/' + n: h for n, h in manifest['files'].items()}
    if set(files) != set(expected):
        raise ValueError('Archive inventory mismatch: extra=' + str(sorted(set(files) - set(expected))) + ' missing=' + str(sorted(set(expected) - set(files))))
    for filename, data in files.items():
        if hashlib.sha256(data).hexdigest() != expected[filename]:
            raise ValueError('Archive file hash mismatch: ' + filename)


def write_linux_archive(package, archive, name):
    def neutral_owner(member):
        member.uid = member.gid = 0
        member.uname = member.gname = ''
        member.mode = 0o755 if member.isdir() or member.name == name + '/Frostmere.x86_64' else 0o644
        return member
    with tarfile.open(archive, 'w:gz') as output:
        output.add(package, arcname=name, filter=neutral_owner)


TARGETS = {
    'windows': ('Windows-x64', 'Windows Playtest', 'Frostmere.exe', 'WINDOWS_PLAYTEST.txt',
                ['windows_release_x86_64.exe', 'windows_debug_x86_64.exe',
                 'windows_release_x86_64_console.exe', 'windows_debug_x86_64_console.exe']),
    'linux': ('Linux-x64', 'Linux Playtest', 'Frostmere.x86_64', 'LINUX_PLAYTEST.txt',
              ['linux_release.x86_64', 'linux_debug.x86_64']),
    'macos': ('macOS-AppleSilicon', 'macOS Playtest', 'Frostmere.app', 'MAC_PLAYTEST.txt', ['macos.zip']),
}


def main(default_target=None):
    configure_console()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target', choices=TARGETS, default=default_target, required=default_target is None)
    parser.add_argument('--godot', help='Explicit engine; otherwise use the pinned host setup')
    parser.add_argument('--templates', required=True, type=Path, help='Official matching export_templates.tpz')
    args = parser.parse_args()
    if args.target == 'macos' and sys.platform != 'darwin':
        parser.error('macOS arm64 packaging requires macOS lipo/codesign tools')
    label, preset, binary_name, instructions, template_files = TARGETS[args.target]
    engine = checked_engine(args.godot)
    version = subprocess.check_output([engine, '--version'], text=True, encoding='utf-8', timeout=15).strip()
    if not re.fullmatch(re.escape(TOOLCHAIN['version']) + r'\.stable\.official\.[A-Za-z0-9]+', version):
        raise ValueError('Godot 4.7.2 stable is required')
    verify_templates(args.templates)
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True, encoding='utf-8').strip()
    dirty = subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'], cwd=ROOT).decode('utf-8')
    if dirty:
        raise ValueError('Commit tracked changes before packaging: ' + dirty.strip())
    name = 'Frostmere-' + label + '-' + revision[:12]
    dist = ROOT / 'dist'
    dist.mkdir(exist_ok=True)
    archive = dist / (name + ('.tar.gz' if args.target == 'linux' else '.zip'))
    if archive.exists():
        raise FileExistsError(f'Package already exists: {archive}')
    logs = ROOT / 'build/packages' / args.target / revision[:12]
    logs.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='staging-', dir=logs) as temp:
        stage = Path(temp) / 'project'
        package = Path(temp) / name
        stage.mkdir()
        package.mkdir()
        tracked = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode('utf-8').split('\0')
        for relative in filter(None, tracked):
            path = Path(relative)
            if path.parts[0] in RUNTIME or relative in {'project.godot', 'export_presets.cfg'}:
                target = stage / path
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / path, target)
        templates = stage / '.tools/export_templates/4.7.2.stable'
        templates.mkdir(parents=True)
        with zipfile.ZipFile(args.templates) as source:
            for filename in template_files:
                (templates / filename).write_bytes(source.read('templates/' + filename))
        if args.target == 'macos':
            # Preserve the existing thin arm64 template behavior, using a verified source.
            with zipfile.ZipFile(templates / 'macos.zip') as source, zipfile.ZipFile(templates / 'macos-arm64.zip', 'w', zipfile.ZIP_DEFLATED) as output:
                for entry in source.infolist():
                    data = source.read(entry)
                    if entry.filename.endswith('.universal'):
                        fat, thin = Path(temp) / 'universal', Path(temp) / 'arm64'
                        fat.write_bytes(data)
                        subprocess.run(['lipo', str(fat), '-thin', 'arm64', '-output', str(thin)], check=True, timeout=60)
                        data = thin.read_bytes()
                        entry.filename = entry.filename.replace('.universal', '.arm64')
                    output.writestr(entry, data)
        run(engine, stage, logs, 'import', '--editor', '--import', '--quit')
        run(engine, stage, logs, 'export', '--export-release', preset, package / binary_name)
        pck = package / 'Frostmere.pck'
        if args.target == 'windows':
            verify_pe(package / 'Frostmere.exe')
            verify_pe(package / 'Frostmere.console.exe')
        elif args.target == 'linux':
            verify_elf(package / binary_name)
            (package / binary_name).chmod(0o755)
        else:
            subprocess.run(['codesign', '--verify', '--deep', '--strict', str(package / binary_name)], check=True, timeout=60)
            packs = list((package / binary_name).rglob('*.pck'))
            if len(packs) != 1:
                raise RuntimeError('Expected exactly one macOS game PCK')
            pck = packs[0]
        if not pck.is_file():
            raise RuntimeError('Missing game PCK')
        run(engine, stage, logs, 'contents', '--main-pack', pck, '--script', ROOT / 'tools/inspect_package.gd')
        if 'PACK_CONTENTS_OK' not in (logs / 'contents.log').read_text(encoding='utf-8'):
            raise RuntimeError('Missing package inspection completion')
        run(engine, ROOT, logs, 'notices', '--script', ROOT / 'tools/export_notices.gd', '--', package / 'GODOT-NOTICES.txt')
        shutil.copyfile(ROOT / 'LICENSE', package / 'LICENSE.txt')
        shutil.copyfile(ROOT / 'docs' / instructions, package / 'READ ME.txt')
        provenance = {'source': 'https://github.com/gonz0w/frostmere', 'revision': revision,
                      'engine': version, 'templates_url': TEMPLATE_URL,
                      'templates_sha256': TEMPLATE_SHA256, 'target': label,
                      'status': 'Development export; native qualification is separate',
                      'files': {p.relative_to(package).as_posix(): digest(p) for p in sorted(package.rglob('*')) if p.is_file()}}
        (package / 'BUILD.json').write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8')
        pending = Path(temp) / archive.name
        if args.target == 'linux':
            write_linux_archive(package, pending, name)
        else:
            with zipfile.ZipFile(pending, 'x', zipfile.ZIP_DEFLATED) as output:
                for path in sorted(package.rglob('*')):
                    if path.is_file():
                        output.write(path, name + '/' + path.relative_to(package).as_posix())
        try:
            verify_bundle(pending, name, args.target)
        except (ValueError, KeyError):
            shutil.copyfile(pending, logs / ('failed-' + archive.name))
            raise
        shutil.move(str(pending), archive)
    Path(str(archive) + '.sha256').write_text(digest(archive) + '  ' + archive.name + '\n', encoding='utf-8')
    print('PACKAGE_CREATED', archive)


if __name__ == '__main__':
    main()
