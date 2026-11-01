"""Run a native macOS soak in a unique QA profile; defaults to four half-hour segments."""
import argparse
import json
import platform
from pathlib import Path
import re
import subprocess
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
ERROR = re.compile(r'SCRIPT ERROR:|ERROR:|\bFAIL(?:\s|:)|failures=[1-9]')


def run_segment(engine, project, log, flags, seconds, report):
    rss = []
    started = time.monotonic()
    next_sample = started
    with log.open('w') as output:
        process = subprocess.Popen([engine, '--path', str(project), '--script',
                                    'tools/native_session_soak.gd', '--'] + flags,
                                   stdout=output, stderr=subprocess.STDOUT)
        try:
            while process.poll() is None:
                now = time.monotonic()
                text = log.read_text(errors='replace')
                if ERROR.search(text):
                    raise RuntimeError(f'Engine error: {log}')
                if now - started > seconds + 120:
                    raise RuntimeError(f'Segment watchdog exceeded: {log}')
                if now >= next_sample:
                    probe = subprocess.run(['ps', '-o', 'rss=', '-p', str(process.pid)], text=True, capture_output=True)
                    if probe.returncode and process.poll() is None:
                        raise RuntimeError('RSS sampling failed while engine was alive')
                    raw = probe.stdout.strip()
                    if raw:
                        rss.append({'seconds': now-started, 'rss_mib': int(raw)/1024})
                    next_sample = now + 5
                time.sleep(1)
            text = log.read_text(errors='replace')
            if process.returncode != 0 or ERROR.search(text) or 'NATIVE_SOAK_COMPLETE failures=0' not in text:
                raise RuntimeError(f'Segment failed: {log}')
            data = json.loads(report.read_text())
            if data['seconds'] < seconds:
                raise RuntimeError('Active workload shorter than requested')
            data['rss_samples'] = rss
            report.write_text(json.dumps(data, indent=2))
            return data
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            # Retain failure evidence without private filesystem/account paths.
            log.write_text(log.read_text(errors='replace').replace(str(ROOT), '<project>').replace(str(Path.home()), '<home>'))
            (log.with_suffix('.rss.json')).write_text(json.dumps(rss, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--seconds', type=int, default=1800)
    parser.add_argument('--segments', type=int, default=4)
    args = parser.parse_args()
    if platform.system() != 'Darwin':
        parser.error('This RSS sampler is qualified only for macOS; do not imply other platform coverage.')
    if not 20 <= args.seconds <= 3600 or not 2 <= args.segments <= 8:
        parser.error('Use 20–3600 seconds and 2–8 segments.')
    engine = str(Path(args.godot).resolve())
    tag = uuid.uuid4().hex[:12]
    out = ROOT/'build/native-soak'/tag
    project = out/'project'
    project.mkdir(parents=True)
    for name in ['scripts', 'scenes', 'shaders', 'data', 'assets', 'tools']:
        (project/name).symlink_to(ROOT/name, target_is_directory=True)
    config = (ROOT/'project.godot').read_text()
    config = config.replace('[application]', '[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="Frostmere-Soak-QA-'+tag+'"')
    (project/'project.godot').write_text(config)
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    summary = {'revision': revision, 'platform': platform.platform(), 'machine': platform.machine(),
               'profile': 'Frostmere-Soak-QA-'+tag, 'requested_seconds': args.seconds,
               'requested_segments': args.segments, 'segments': [], 'passed': False,
               'qualification_duration_met': False,
               'method': 'Native 1280x800 Mobile renderer capped at 60 FPS. Real AI and scripted melee, seeded prerequisites/materials, invulnerable player and enlarged enemy health. Ordinary craft, travel, autosave and explicit save. RSS sampled by macOS ps separately from Godot allocator. Not human play or balance qualification.'}
    def save_summary():
        (out/'summary.json').write_text(json.dumps(summary, indent=2))
    save_summary()
    print('SOAK_OUTPUT '+str(out), flush=True)
    try:
        with (out/'import.log').open('w') as log:
            result = subprocess.run([engine, '--headless', '--path', str(project), '--editor', '--import', '--quit'], stdout=log, stderr=subprocess.STDOUT, timeout=180)
        if result.returncode or ERROR.search((out/'import.log').read_text(errors='replace')):
            raise RuntimeError('Isolated project import failed')
        for i in range(args.segments):
            report = out/f'segment-{i+1}.json'
            flags = [f'--seconds={args.seconds}', f'--report={report}']
            if i == 0:
                flags.append('--prepare')
            data = run_segment(engine, project, out/f'segment-{i+1}.log', flags, args.seconds, report)
            if i > 0 and 'SOAK_RESTART_VERIFIED' not in (out/f'segment-{i+1}.log').read_text():
                raise RuntimeError('Restart verification missing')
            summary['segments'].append(data)
            save_summary()
            print(f'SOAK_SEGMENT_COMPLETE {i+1}/{args.segments} seconds={data["seconds"]:.1f}', flush=True)
        summary['passed'] = True
        summary['qualification_duration_met'] = sum(s['seconds'] for s in summary['segments']) >= 7200 and len(summary['segments']) >= 4
        save_summary()
        print('NATIVE_SOAK_RUN_COMPLETE qualification_duration_met='+str(summary['qualification_duration_met']), flush=True)
    except Exception as exc:
        summary['error'] = str(exc).replace(str(ROOT), '<project>').replace(str(Path.home()), '<home>')
        save_summary()
        raise


if __name__ == '__main__':
    main()
