"""Reject mismatched templates and non-x64 binaries before distribution."""
from pathlib import Path
import tempfile
import unittest

import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import package_game as package

class PackageTests(unittest.TestCase):
    def test_wrong_archive_digest(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'templates.tpz'
            path.write_bytes(b'wrong archive')
            with self.assertRaisesRegex(ValueError, 'checksum'):
                package.verify_templates(path)

    def test_wrong_pe_architecture(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'game.exe'
            data = bytearray(128)
            data[:2] = b'MZ'
            data[60:64] = (64).to_bytes(4, 'little')
            data[64:68] = b'PE\0\0'
            data[68:70] = (0xaa64).to_bytes(2, 'little')
            path.write_bytes(data)
            with self.assertRaisesRegex(ValueError, 'x86_64'):
                package.verify_pe(path)
            data[68:70] = (0x8664).to_bytes(2, 'little')
            path.write_bytes(data)
            package.verify_pe(path)
