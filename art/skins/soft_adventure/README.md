# soft_adventure 그린 스킨 생성 기록

공통 묶음 기본 스킨 `godot/addons/seorilabs_game/skins/soft_adventure/`의 PNG 9분할과 아이콘을 만든 기록이다. 공통 묶음(ROOTS) 밖에 두어 소비 게임에 설치되지 않는다.

- 방향: 2026-11-06 사용자 선택 시안 A 나무·가죽 어드벤처(설계 `docs/design/2026-11-06-ui-kit-painted-skin/`).
- `style/style-guide.md`: 재질·색·빛 규칙. `style/ui-reference.png`: 선택 시안에서 뽑은 UI 기준 crop(생성 참조).
- `asset-manifest.json`: 프롬프트, 참조, 모델, 최종 크기, 후처리 순서(`postprocess`).
- 생성 원본(raw)과 시안 3안: NAS1dual `agent-artifacts/game-foundation/2026-11-06/4e9c7aa0fc820c9f80ebb8ed18878bc90aadba82/ui-kit-painted-skin-raw/`. raw는 Gemini 출력에 크로마키와 16:9 자르기를 적용한 상태다.

## 다시 만들기

1. 생성(유료 API): `game-asset-pipeline`의 `generate_assets.py --manifest art/skins/soft_adventure/asset-manifest.json --only <이름> --force`. raw는 `art/skins/soft_adventure/raw/`에 생기며 커밋하지 않고 NAS로 옮긴다.
2. 후처리(API 없음): `python3 tools/skin_postprocess.py --manifest art/skins/soft_adventure/asset-manifest.json --raw <raw 폴더> --out godot/addons/seorilabs_game/skins/soft_adventure`. 크로마키, 비율 자르기, 크기 맞춤, 투명 여백 자르기, 타일 이음매 처리를 manifest 순서대로 한다. NAS raw로 돌리면 버튼과 아이콘은 커밋된 파일과 픽셀이 같다.
3. 테마: `godot --headless --path godot --import --quit-after 2` 뒤 `godot --headless --path godot --script res://addons/seorilabs_game/ui_kit/build_theme.gd`.
4. 검사: `npm test`(`test_ui_kit.py`가 manifest의 타일 margins와 `skin.json` margins 일치를 본다), `python3 tools/check.py --capture --size <크기>`.
