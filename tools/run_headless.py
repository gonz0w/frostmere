"""Run the bounded core headless checks with retained logs; Python 3.11+."""
import argparse
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ERROR = re.compile(r'SCRIPT ERROR:|ERROR:|\bFAIL(?:\s|:)|failures=[1-9]')
SUITES = [('ci_isolation', 'ISOLATION_COMPLETE failures=0'),
          ('smoke', 'SMOKE_COMPLETE failures=0'),
          ('characters', 'CHARACTERS_COMPLETE checks=36 failures=0'),
          ('session_save', 'SESSION_COMPLETE checks=73 failures=0'),
          ('save_recovery', 'failures=0')]


def run_check(name, command, log, timeout, marker=None):
    log = Path(log)
    log.parent.mkdir(parents=True, exist_ok=True)
    timed_out = False
    code = None
    with log.open('w', encoding='utf-8') as output:
        try:
            result = subprocess.run(command, stdout=output, stderr=subprocess.STDOUT,
                                    timeout=timeout, cwd=ROOT)
            code = result.returncode
        except subprocess.TimeoutExpired:
            timed_out = True
            output.write('\nRUNNER TIMEOUT\n')
        except OSError as exc:
            output.write(f'RUNNER START FAILURE: {exc}\n')
    text = log.read_text(encoding='utf-8', errors='replace')
    # Public logs need diagnostic content, not local account or checkout paths.
    text = text.replace(str(ROOT), '<project>').replace(str(Path.home()), '<home>')
    log.write_text(text, encoding='utf-8')
    passed = code == 0 and not timed_out and not ERROR.search(text)
    if marker is not None:
        passed = passed and marker in text
    return {'name': name, 'exit_code': code, 'timed_out': timed_out,
            'passed': bool(passed), 'log': log.name}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--smoke', action='store_true', help='Only import, isolation and movement smoke')
    parser.add_argument('--godot', required=True, help='Godot 4.7.2 executable or PATH command')
    parser.add_argument('--logs', type=Path, default=ROOT / 'build/ci')
    parser.add_argument('--timeout', type=int, default=180, help='Seconds per import/suite (1–600)')
    args = parser.parse_args()
    if not 1 <= args.timeout <= 600:
        parser.error('--timeout must be between 1 and 600 seconds')
    args.logs.mkdir(parents=True, exist_ok=True)
    checks = []
    version = run_check('version', [args.godot, '--version'], args.logs/'version.log', 15)
    version_text = (args.logs/'version.log').read_text(encoding='utf-8').strip()
    version['passed'] = version['passed'] and bool(re.fullmatch(r'4\.7\.2\.stable(?:\.[A-Za-z0-9_-]+)*', version_text))
    checks.append(version)
    commands = [('import', ['--editor', '--import', '--quit'], None)]
    commands += [(name, ['--script', f'tests/{name}.gd'], marker) for name, marker in SUITES]
    commands += [('recovery_prepare', ['--script', 'tests/recovery_restart.gd', '--', '--prepare'], 'RECOVERY_RESTART_PREPARED'),
                 ('recovery_restart', ['--script', 'tests/recovery_restart.gd'], 'RECOVERY_RESTART_COMPLETE failures=0')]
    if args.smoke:
        commands = commands[:3]
    commands += [('migration_prepare', ['--script', 'tests/save_migration.gd', '--', '--prepare'], 'MIGRATION_PREPARED'),
                 ('migration_restart', ['--script', 'tests/save_migration.gd'], 'MIGRATION_COMPLETE failures=0')]
    commands += [('control_settings', ['--script', 'tests/control_settings.gd'], 'CONTROL_SETTINGS_COMPLETE failures=0'),
                 ('control_input', ['--script', 'tests/control_input.gd'], 'CONTROL_INPUT_COMPLETE failures=0')]
    commands += [('accessibility', ['--script', 'tests/accessibility.gd'], 'ACCESSIBILITY_COMPLETE failures=0')]
    if version['passed']:
        for name, flags, marker in commands:
            result = run_check(name, [args.godot, '--headless', '--path', str(ROOT)] + flags,
                               args.logs/f'{name}.log', args.timeout, marker)
            checks.append(result)
            print(f"{name}: {'PASS' if result['passed'] else 'FAIL'}", flush=True)
            if not result['passed']:
                break
    success = len(checks) == len(commands) + 1 and all(check['passed'] for check in checks)
    (args.logs/'results.json').write_text(json.dumps({'passed': success, 'checks': checks}, indent=2)+'\n')
    print('HEADLESS_CHECKS_PASSED' if success else 'HEADLESS_CHECKS_FAILED (see logs)')
    return 0 if success else 1


if __name__ == '__main__':
    raise SystemExit(main())
