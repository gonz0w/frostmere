"""Bounded Linux editor-import investigation; never substitutes for source checks."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

from run_headless import ROOT, run_check


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    args = parser.parse_args()
    engine = str(Path(args.godot).resolve())
    debugger = shutil.which('gdb')
    if debugger is None:
        parser.error('GDB is required; no diagnostic attempt was run')
    logs = ROOT / 'build/import-diagnostics'
    logs.mkdir(parents=True, exist_ok=True)
    paths = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
    results = []
    for attempt in range(1, 4):
        with tempfile.TemporaryDirectory(prefix='source-', dir=logs) as temporary:
            project = Path(temporary)
            for name in filter(None, paths):
                source = ROOT / name
                if source.is_file():
                    target = project / name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(source, target)
            command = [debugger, '--batch', '--return-child-result',
                       '-ex', 'set pagination off', '-ex', 'run',
                       '-ex', 'thread apply all bt', '-ex', 'info program',
                       '--args', engine, '--headless', '--path', str(project),
                       '--editor', '--import', '--quit', '--verbose']
            result = run_check(f'import-{attempt}', command, logs/f'import-{attempt}.log', 180)
            results.append(result)
            (logs/'results.json').write_text(json.dumps(results, indent=2)+'\n')
            print(json.dumps(result), flush=True)
    # Every observation counts. A later pass cannot cancel an earlier failure.
    return 0 if all(result['passed'] for result in results) else 1


if __name__ == '__main__':
    raise SystemExit(main())
