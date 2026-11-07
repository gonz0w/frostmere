"""Launch Frostmere from source or run isolated verification; Python 3.11+."""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys

from toolchain import MANIFEST, ROOT, verify_version, configure_console
from run_headless import run_check


def candidates():
    host = {'darwin': 'macos', 'win32': 'windows', 'linux': 'linux'}.get(sys.platform)
    if host:
        yield ROOT / '.tools/pinned' / host / MANIFEST['artifacts'][host]['executables'][0]
    found = shutil.which('godot')
    if found:
        yield Path(found)
    if sys.platform == 'darwin':
        yield Path('/Applications/Godot.app/Contents/MacOS/Godot')
        yield ROOT / '.tools/Godot.app/Contents/MacOS/Godot'


def resolve_engine(explicit):
    if explicit:
        found = shutil.which(explicit)
        if found:
            return str(Path(found).resolve())
        raise ValueError('Godot executable not found: ' + explicit)
    for path in candidates():
        if path.is_file() and shutil.which(str(path)):
            return str(path.resolve())
    raise ValueError('Godot not found. Run python3 tools/toolchain.py --install <macos|windows|linux> or pass --godot PATH.')


def checked_engine(explicit):
    engine = resolve_engine(explicit)
    try:
        version = subprocess.check_output([engine, '--version'], text=True, encoding='utf-8',
                                          errors='replace', stderr=subprocess.STDOUT, timeout=15)
    except (OSError, subprocess.SubprocessError) as exc:
        raise ValueError('Could not start Godot for version verification; check the executable and permissions.') from exc
    verify_version(version)
    return engine


def main(argv=None):
    configure_console()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', help='Explicit executable path or PATH command; otherwise use pinned setup, then PATH')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--smoke', action='store_true', help='Import and run isolated save-isolation/movement smoke checks')
    mode.add_argument('--verify', action='store_true', help='Run the full bounded core headless suite')
    args = parser.parse_args(argv)
    try:
        engine = checked_engine(args.godot)
        if args.smoke or args.verify:
            command = [sys.executable, str(ROOT / 'tools/run_headless.py'), '--godot', engine]
            if args.smoke:
                command += ['--smoke']
            return subprocess.call(command, cwd=ROOT)
        result = run_check('import', [engine, '--headless', '--path', str(ROOT), '--editor', '--import', '--quit'],
                           ROOT / 'build/launch/import.log', 180)
        if not result['passed']:
            raise ValueError('Import failed; inspect build/launch/import.log. Game was not started.')
        # This is intentional normal play; verification modes above never enter it.
        return subprocess.call([engine, '--path', str(ROOT)], cwd=ROOT)
    except (ValueError, OSError) as exc:
        print('Cannot start Frostmere: ' + str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
