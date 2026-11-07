"""Artifact-level checks: ELF architecture, inventory integrity, Linux execute bit."""
from pathlib import Path
import sys
import tempfile
import unittest
import json
import tarfile
import hashlib
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import package_game as package

class PortablePackageTests(unittest.TestCase):
    def test_elf_rejects_wrong_architecture(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / 'game'
            data = bytearray(64); data[:6] = b'\x7fELF\x02\x01'
            data[18:20] = (183).to_bytes(2, 'little'); path.write_bytes(data)
            with self.assertRaisesRegex(ValueError, 'x86_64'):
                package.verify_elf(path)
            data[18:20] = (62).to_bytes(2, 'little'); path.write_bytes(data)
            package.verify_elf(path)

    def test_archive_rejects_tampering_and_missing_execute_bit(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); stage = root / 'Frostmere'; stage.mkdir()
            binary = stage / 'Frostmere.x86_64'; binary.write_bytes(b'binary'); binary.chmod(0o755)
            manifest = {'files': {'Frostmere.x86_64': hashlib.sha256(b'binary').hexdigest()}}
            (stage / 'BUILD.json').write_text(json.dumps(manifest))
            def archive():
                p = root / 'bundle.tar.gz'
                with tarfile.open(p, 'w:gz') as out: out.add(stage, arcname='Frostmere')
                return p
            package.verify_bundle(archive(), 'Frostmere', 'linux')
            binary.chmod(0o644)
            with self.assertRaisesRegex(ValueError, 'executable'):
                package.verify_bundle(archive(), 'Frostmere', 'linux')
            binary.chmod(0o755); binary.write_bytes(b'changed')
            with self.assertRaisesRegex(ValueError, 'hash'):
                package.verify_bundle(archive(), 'Frostmere', 'linux')
