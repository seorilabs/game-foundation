import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEV = 'addons/seorilabs_game/dev/**'

def presets(text):
    found = []
    for block in re.split(r'^\[preset\.\d+\]\s*$', text, flags=re.M)[1:]:
        fields = dict(re.findall(r'^(\w+)="(.*)"$', block.split('[preset.')[0], flags=re.M))
        found.append(fields)
    return found

class ExportPresetTests(unittest.TestCase):
    """테스트실(dev/)은 디버그 실행과 playtest 기능 태그 빌드에만 둔다. 그 밖의 export는 파일을 빼야 한다."""
    def test_web_preset_excludes_test_room(self):
        found = presets((ROOT / 'godot/export_presets.cfg').read_text())
        web = [p for p in found if p.get('platform') == 'Web']
        self.assertTrue(web, 'Web preset')
        for preset in found:
            if 'playtest' in preset.get('custom_features', '').split(','):
                continue
            self.assertIn(DEV, preset.get('exclude_filter', '').split(','), preset.get('name'))

    def test_test_room_is_loaded_only_at_runtime(self):
        addon = ROOT / 'godot/addons/seorilabs_game'
        self.assertEqual({'test_room.gd', 'test_room.tscn'}, {p.name for p in (addon / 'dev').iterdir() if p.suffix in ('.gd', '.tscn')})
        for path in (addon / 'dev').glob('*.gd'):
            self.assertNotRegex(path.read_text(), r'(?m)^class_name', str(path))
        for path in addon.rglob('*.gd'):
            self.assertNotIn('preload("res://addons/seorilabs_game/dev/', path.read_text(), str(path))

if __name__ == '__main__': unittest.main()
