import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('toolchain', Path(__file__).resolve().parents[1] / 'tools/toolchain.py')
t = importlib.util.module_from_spec(spec)
spec.loader.exec_module(t)

class ToolchainTests(unittest.TestCase):
    def test_checksum_rejects_modified_archive(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'engine.zip'; p.write_bytes(b'bad')
            with self.assertRaisesRegex(ValueError, 'checksum'):
                t.verify_archive(p, '0' * 64)

    def test_version_rejects_wrong_engine(self):
        for value in ['4.7.1.stable', '4.7.2.dev', '4.7.2.stable.mono.abc']:
            with self.assertRaisesRegex(ValueError, 'version'):
                t.verify_version(value)
        t.verify_version('4.7.2.stable.official.ed1daf0bf')

    def test_case_collision_and_reference(self):
        paths = ['scripts/Thing.gd', 'scripts/thing.gd']
        self.assertTrue(t.case_errors(paths, {}))
        self.assertTrue(t.case_errors(['scripts/thing.gd'], {'scenes/main.tscn': 'path="res://scripts/Thing.gd"'}))
        self.assertEqual([], t.case_errors(['scripts/thing.gd'], {'scenes/main.tscn': 'path="res://scripts/thing.gd"'}))
