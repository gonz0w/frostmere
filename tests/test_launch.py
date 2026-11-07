"""Portable source launcher rejects bad engines before starting a game."""
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import play

class LaunchTests(unittest.TestCase):
    def test_missing_explicit_engine_never_falls_back(self):
        with self.assertRaisesRegex(ValueError, 'not found'):
            play.resolve_engine('/definitely/missing/godot')

    def test_wrong_version_never_launches(self):
        with patch.object(play.subprocess, 'check_output', return_value='4.6.stable.official.abc'):
            with self.assertRaisesRegex(ValueError, 'version'):
                play.checked_engine(sys.executable)

    def test_path_with_spaces_and_unicode_is_one_argument(self):
        with tempfile.TemporaryDirectory(prefix='Frostmere QA 雪 ') as folder:
            engine = Path(folder) / 'godot test.exe'
            engine.write_bytes(b'fixture')
            engine.chmod(0o755)
            with patch.object(play.subprocess, 'check_output', return_value='4.7.2.stable.official.ed1daf0bf') as probe:
                self.assertEqual(str(engine.resolve()), play.checked_engine(str(engine)))
                self.assertEqual([str(engine.resolve()), '--version'], probe.call_args.args[0])

    def test_no_available_engine_has_setup_hint(self):
        with patch.object(play, 'candidates', return_value=[]):
            with self.assertRaisesRegex(ValueError, 'toolchain.py'):
                play.resolve_engine(None)

    def test_smoke_delegates_only_to_isolated_runner(self):
        with patch.object(play, 'checked_engine', return_value='/engine path/Godot'), patch.object(play.subprocess, 'call', return_value=0) as call:
            self.assertEqual(0, play.main(['--smoke']))
            self.assertIn('--smoke', call.call_args.args[0])
            self.assertIn(str(play.ROOT / 'tools/run_headless.py'), call.call_args.args[0])
            self.assertIn('/engine path/Godot', call.call_args.args[0])

    def test_regression_uses_all_groups_and_propagates_failure(self):
        with patch.object(play, 'checked_engine', return_value='/engine path/Godot'), patch.object(play.subprocess, 'call', return_value=1) as call:
            self.assertEqual(1, play.main(['--regression']))
            command = call.call_args.args[0]
            self.assertEqual(command[command.index('--group')+1], 'all')
            self.assertIn(str(play.ROOT / 'tools/run_headless.py'), command)

    def test_engine_failure_does_not_enter_game(self):
        with patch.object(play, 'checked_engine', side_effect=ValueError('wrong version')), patch.object(play.subprocess, 'call') as call:
            self.assertEqual(1, play.main([]))
            call.assert_not_called()

    def test_failed_import_prevents_normal_play(self):
        with patch.object(play, 'checked_engine', return_value='/engine path/Godot'), patch.object(play, 'run_check', return_value={'passed': False}), patch.object(play.subprocess, 'call') as call:
            self.assertEqual(1, play.main([]))
            call.assert_not_called()

    def test_normal_play_starts_only_after_import(self):
        with patch.object(play, 'checked_engine', return_value='/engine path/Godot'), patch.object(play, 'run_check', return_value={'passed': True}) as check, patch.object(play.subprocess, 'call', return_value=0) as call:
            self.assertEqual(0, play.main([]))
            check.assert_called_once()
            call.assert_called_once_with(['/engine path/Godot', '--path', str(play.ROOT)], cwd=play.ROOT)

    def test_setup_reports_unicode_path_on_legacy_console(self):
        import os
        import subprocess
        source = "from tools import toolchain as t; from pathlib import Path; import sys; t.install=lambda *a: Path('Frostmere QA 雪/Godot'); sys.argv=['toolchain.py','--install','windows']; t.main()"
        env = dict(os.environ, PYTHONIOENCODING='cp1252')
        result = subprocess.run([sys.executable, '-c', source], cwd=play.ROOT, env=env, capture_output=True)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn('Frostmere QA 雪', result.stdout.decode('utf-8'))
