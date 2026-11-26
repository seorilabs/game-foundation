"""묶음으로 배포되는 공용 probe가 소비 게임의 기준 해상도에서도 통과하는지 검사한다.

starter-template-game처럼 기준 크기가 1280x720(canvas_items 늘이기)인 프로젝트에서는
probe가 넣는 탭 좌표가 늘이기 변환으로 옮겨져 실패한 적이 있다(독립 검수 3회차 R3-1).
프로젝트 복사본에 override.cfg로 기준 크기만 바꿔 ui_kit_probe와 dev_probe를 돌린다.
"""

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot"
GODOT = os.environ.get("GODOT", "godot")
OVERRIDE = """[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
"""


@unittest.skipUnless(shutil.which(GODOT), "godot 실행 파일이 없다")
class ConsumerScaleTests(unittest.TestCase):
    def test_shared_probes_pass_with_1280x720_base_size(self):
        with tempfile.TemporaryDirectory() as tmp:
            copy = Path(tmp) / "godot"
            shutil.copytree(PROJECT, copy, ignore=shutil.ignore_patterns("build", ".godot"))
            (copy / "override.cfg").write_text(OVERRIDE, encoding="utf-8")
            env = dict(os.environ, HOME=tmp)
            subprocess.run([GODOT, "--headless", "--path", str(copy), "--import", "--quit-after", "2"],
                           capture_output=True, text=True, timeout=300, env=env, check=False)
            for script, name in (("res://tests/common/ui_kit_probe.gd", "ui-kit.json"), ("res://tests/common/dev_probe.gd", "dev.json")):
                out = Path(tmp) / name
                run = subprocess.run([GODOT, "--headless", "--path", str(copy), "--script", script, "--", "--out", str(out)],
                                     capture_output=True, text=True, timeout=180, env=env, check=False)
                self.assertEqual(run.returncode, 0, f"{script} 실패\n{run.stdout[-2000:]}\n{run.stderr[-2000:]}")
                report = json.loads(out.read_text(encoding="utf-8"))
                failed = [c for c in report.get("checks", []) if not c.get("passed", False)]
                self.assertFalse(failed, f"{script} 실패 항목: {failed[:5]}")


if __name__ == "__main__":
    unittest.main()
