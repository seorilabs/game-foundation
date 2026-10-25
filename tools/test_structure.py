import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class StructureTest(unittest.TestCase):
    def test_common_has_no_product_dependencies(self):
        common = ROOT / 'godot/addons/seorilabs_game'
        self.assertTrue(common.is_dir(), '공통 원본이 addon에 있어야 한다')
        for path in common.rglob('*.gd'):
            code = path.read_text()
            self.assertNotIn('res://reference/', code, str(path))
            self.assertNotIn('res://game/', code, str(path))
            for name in ('SKYWAY', 'Mira', 'WINDWARD ISLES', 'Lost lighthouse'):
                self.assertNotIn(name, code, str(path))

    def test_reference_is_real_entrypoint(self):
        self.assertIn('res://reference/bootstrap/main.tscn', (ROOT / 'godot/project.godot').read_text())

    def test_no_agent_dependency(self):
        for path in (ROOT / 'tools').glob('*.py'):
            if path == Path(__file__):
                continue
            self.assertNotIn('Path.home()', path.read_text(), str(path))
            self.assertNotIn('AGENT_HOME', path.read_text(), str(path))

if __name__ == '__main__':
    unittest.main()
