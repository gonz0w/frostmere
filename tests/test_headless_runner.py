"""Exercise failure detection with real subprocesses, without Godot."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('runner', Path(__file__).resolve().parents[1] / 'tools/run_headless.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)

class RunnerTests(unittest.TestCase):
    def run_probe(self, source, marker='PROBE_COMPLETE failures=0', timeout=3):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'probe.log'
            result = runner.run_check('probe', [sys.executable, '-c', source], path, timeout, marker)
            return result, path.read_text()

    def test_success(self):
        result, log = self.run_probe("print('PROBE_COMPLETE failures=0')")
        self.assertTrue(result['passed'])
        self.assertIn('PROBE_COMPLETE', log)

    def test_zero_exit_error_is_failure(self):
        for message in ['SCRIPT ERROR: broken', 'ERROR: invalid resource', 'FAIL assertion', 'PROBE_COMPLETE failures=2']:
            with self.subTest(message=message):
                result, _ = self.run_probe(f"print({message!r}); print('PROBE_COMPLETE failures=0')")
                self.assertFalse(result['passed'])

    def test_missing_completion_is_failure(self):
        result, _ = self.run_probe("print('started')")
        self.assertFalse(result['passed'])

    def test_nonzero_exit_is_failure(self):
        result, _ = self.run_probe("print('PROBE_COMPLETE failures=0'); raise SystemExit(1)")
        self.assertFalse(result['passed'])

    def test_timeout_retains_output(self):
        result, log = self.run_probe("import time; print('started', flush=True); time.sleep(10)", timeout=1)
        self.assertFalse(result['passed'])
        self.assertTrue(result['timed_out'])
        self.assertIn('started', log)

    def test_missing_executable_is_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            result = runner.run_check('missing', [str(Path(directory)/'absent')], Path(directory)/'log', 1)
            self.assertFalse(result['passed'])

if __name__ == '__main__':
    unittest.main()
