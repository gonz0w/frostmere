"""Check that soak orchestration rejects false success without running the game."""
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from run_native_soak import run_segment


class SoakFailureDetection(unittest.TestCase):
    def run_fake(self, body):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            report = root/'report.json'
            engine = root/'fake-engine'
            engine.write_text(f'#!{sys.executable}\nfrom pathlib import Path\nreport=Path({str(report)!r})\n'+body)
            engine.chmod(0o700)
            return run_segment(str(engine), root, root/'engine.log', [], 1, report)

    def test_zero_exit_script_error_rejected(self):
        with self.assertRaises(RuntimeError):
            self.run_fake("print('SCRIPT ERROR: deliberately failed')\n")

    def test_missing_completion_rejected(self):
        with self.assertRaises(RuntimeError):
            self.run_fake("report.write_text('{\"seconds\":1}')\n")

    def test_short_active_duration_rejected(self):
        with self.assertRaises(RuntimeError):
            self.run_fake("report.write_text('{\"seconds\":0}')\nprint('NATIVE_SOAK_COMPLETE failures=0')\n")

    def test_completed_report_accepted(self):
        result = self.run_fake("report.write_text('{\"seconds\":1}')\nprint('NATIVE_SOAK_COMPLETE failures=0')\n")
        self.assertEqual(result['seconds'], 1)
        self.assertIn('rss_samples', result)


if __name__ == '__main__':
    unittest.main()
