import json
import re
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / 'godot/addons/seorilabs_game'
SKIN = ADDON / 'skins/soft_adventure'
KIT = ADDON / 'ui_kit'

class UiKitTests(unittest.TestCase):
    def test_skin_v2_references_existing_textures_fonts_and_icons(self):
        skin = json.loads((SKIN / 'skin.json').read_text())
        self.assertEqual('1.1.0', skin['contract'])
        for name, spec in skin['textures'].items():
            for state in ('normal', 'pressed', 'disabled'):
                if state in spec:
                    self.assertTrue((SKIN / spec[state]).is_file(), name + ':' + state)
            self.assertEqual(4, len(spec['margins']), name)
            self.assertEqual(4, len(spec['content']), name)
        for role in ('display_en', 'display_ko', 'body', 'number'):
            self.assertTrue((ROOT / 'godot' / skin['fonts'][role].replace('res://', '')).is_file(), role)
        for icon in skin['icons'].values():
            self.assertTrue((SKIN / icon).is_file(), icon)
        self.assertEqual({'body', 'label', 'title', 'display', 'action', 'number'}, set(skin['sizes']))

    def test_theme_resource_uses_two_fonts_and_painted_skins(self):
        text = (SKIN / 'theme.tres').read_text()
        fonts = set(re.findall(r'type="FontFile" path="([^"]+)"', text))
        self.assertGreaterEqual(len(fonts), 2, fonts)
        self.assertIn('StyleBoxTexture', text)
        self.assertNotIn('uid="uid://', text)
        for texture in re.findall(r'type="Texture2D" path="res://([^"]+)"', text):
            self.assertTrue((ROOT / 'godot' / texture).is_file(), texture)

    def test_kit_has_fixed_inventory_and_no_product_dependency(self):
        expected = {'theme_builder.gd', 'build_theme.gd', 'juice.gd', 'ui_sfx.gd', 'hud_layers.gd', 'hud_layers.tscn', 'currency_chip.gd', 'currency_chip.tscn',
                    'popup_base.gd', 'popup_base.tscn', 'reward_ceremony.gd', 'reward_ceremony.tscn'}
        self.assertEqual(expected, {p.name for p in KIT.iterdir() if p.is_file() and p.suffix in ('.gd', '.tscn')})
        self.assertEqual({'burst.tscn', 'sparkle.tscn'}, {p.name for p in (KIT / 'particles').glob('*.tscn')})
        for p in KIT.rglob('*'):
            if p.suffix in ('.gd', '.tscn'):
                self.assertNotRegex(p.read_text(), r'res://(?:game|reference)/', str(p))

    def test_sfx_set_and_license(self):
        self.assertEqual({'tap', 'confirm', 'cancel', 'error', 'reward_sting'}, {p.stem for p in (KIT / 'sfx').glob('*.wav')})
        self.assertIn('CC0', (KIT / 'sfx/LICENSE.md').read_text())
        for wav in (KIT / 'sfx').glob('*.wav'):
            self.assertLess(wav.stat().st_size, 200_000, wav.name)

    def test_painted_skin_record_matches_skin_json(self):
        # 생성 기록(manifest)의 후처리 margins가 skin.json과 같아야 재생성한 PNG가 같은 9분할로 맞는다.
        manifest = json.loads((ROOT / 'art/skins/soft_adventure/asset-manifest.json').read_text())
        skin = json.loads((SKIN / 'skin.json').read_text())
        by_file = {}
        for key, spec in skin['textures'].items():
            for state in ('normal', 'pressed', 'disabled'):
                if state in spec:
                    by_file[spec[state]] = spec
        for asset in manifest['assets']:
            name = asset['name'] + '.png'
            self.assertTrue((SKIN / name).is_file(), name)
            # 기대 최종 크기가 기록돼 있어 재생성한 PNG의 크기가 달라지면 후처리 도구가 멈춘다.
            head = (SKIN / name).read_bytes()[16:24]
            self.assertEqual(asset['postprocess'].get('expect_size'), [int.from_bytes(head[:4], 'big'), int.from_bytes(head[4:], 'big')], name)
            tile = asset.get('postprocess', {}).get('tileable')
            if tile:
                self.assertEqual(tile['margins'], by_file[name]['margins'], name)
                self.assertTrue(all(a.startswith('tile') for a, axis in zip(by_file[name]['axis'], 'hv') if axis in tile['axes']), name)
        self.assertFalse((SKIN / 'art').exists(), 'generation records stay outside the shared bundle')

    def test_motion_defaults_match_skin_table(self):
        skin = json.loads((SKIN / 'skin.json').read_text())['motion']
        juice = (KIT / 'juice.gd').read_text()
        self.assertIn('seconds := %.2f' % (skin['pop_in_ms'] / 1000), juice)
        self.assertIn('seconds := %.2f' % (skin['pop_out_ms'] / 1000), juice)
        self.assertIn('seconds := %.1f' % (skin['press_punch_ms'] / 1000), juice)

if __name__ == '__main__': unittest.main()
