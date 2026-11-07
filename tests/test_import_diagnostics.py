"""Check bounded diagnostic snapshots and failure aggregation without an engine."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import diagnose_import


class ImportDiagnosticTests(unittest.TestCase):
    def test_failed_observation_is_not_hidden_and_snapshots_are_clean(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root/'project.godot').write_text('[application]\n')
            (root/'untracked-secret').write_text('never copied')
            projects = []

            def observe(name, command, log, timeout):
                project = Path(command[command.index('--path')+1])
                projects.append(project)
                self.assertEqual((project/'project.godot').read_text(), '[application]\n')
                self.assertFalse((project/'untracked-secret').exists())
                self.assertFalse((project/'generated').exists())
                (project/'generated').write_text('import output')
                self.assertIn('--return-child-result', command)
                self.assertEqual(timeout, 180)
                return {'name': name, 'passed': len(projects) != 1, 'exit_code': 1 if len(projects) == 1 else 0}

            with patch.object(diagnose_import, 'ROOT', root), \
                 patch.object(diagnose_import.shutil, 'which', return_value='/usr/bin/gdb'), \
                 patch.object(diagnose_import.subprocess, 'check_output', return_value=b'project.godot\0'), \
                 patch.object(diagnose_import, 'run_check', side_effect=observe), \
                 patch.object(sys, 'argv', ['diagnose_import', '--godot', '/pinned/godot']):
                self.assertEqual(diagnose_import.main(), 1)
            self.assertEqual(len(projects), 3)
            self.assertTrue(all(not path.exists() for path in projects))
            results = json.loads((root/'build/import-diagnostics/results.json').read_text())
            self.assertEqual([row['passed'] for row in results], [False, True, True])


if __name__ == '__main__':
    unittest.main()
