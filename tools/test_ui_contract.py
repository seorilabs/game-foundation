import json
import tempfile
import unittest
from pathlib import Path
import validate_outgame as gate

class UiContractVersionTests(unittest.TestCase):
    """계약 1.2.0은 스킨을 바꾸지 않는다. 제품 스킨의 skin.json 계약은 1.1.0 그대로 1.2.0 아래에서 통과한다."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / 'skin').mkdir()

    def skin(self, contract):
        (self.root / 'skin/skin.json').write_text(json.dumps({'id': 'holo', 'contract': contract}))
        return {'skin': 'holo', 'resources': ['skin/skin.json']}

    def test_product_skin_keeps_1_1_0_under_ui_standard_1_2_0(self):
        self.assertTrue(gate.declared_skin(self.root, {**self.skin('1.1.0'), 'version': '1.2.0'}))
        self.assertTrue(gate.declared_skin(self.root, {**self.skin('1.1.0'), 'version': '1.1.0'}))
        self.assertFalse(gate.declared_skin(self.root, {**self.skin('1.1.0'), 'version': '1.0.0'}))
        self.assertFalse(gate.declared_skin(self.root, {**self.skin('1.2.0'), 'version': '1.1.0'}))

    def test_known_ui_standard_versions(self):
        self.assertEqual(('1.0.0', '1.1.0', '1.2.0'), gate.UI_VERSIONS)

if __name__ == '__main__': unittest.main()
