# 설계: ui_kit 스킨 v3, 그린 질감 스킨 파이프라인

- 설계 ID·버전·원본 커밋: 2026-11-06-ui-kit-painted-skin v1, 기준 main `925cc8c629f58b9619d1b8fc7972a326714e341a`
- 상태: 승인
- 승인자·시각·근거·승인 커밋: Ilhwan Seo, 2026-11-06, 시안 A(나무·가죽 어드벤처) 선택과 함께 "제안 작업 좋다"·세션 질의 응답으로 승인. 시안 3안은 `build/skin-concepts/`(로컬)와 NAS에 둔다. 승인 커밋 `b3f8c18`
- 관련: agent-config 스킬 `game-ui-commercial`·`game-asset-pipeline`(`references/ui-skins.md`)·`game-ui-design`, [ui_kit 설계](../2026-11-05-ui-kit/design.md), [가로 보정](../2026-11-06-ui-kit-landscape/design.md)

## 목적·범위·근거

사용자의 핵심 관심은 "시중 상용 게임처럼 게임으로 보이는 화면"이다(2026-11-06). 필수 재료 게이트는 재료 누락을 막지만, 상용 게임과의 차이는 재료의 질에서 난다. 지금 기본 스킨 soft_adventure는 벡터 9분할(색면 + 1~2px 선)이라 키 비주얼(그린 여우 일러스트)과 UI 표면의 질감 차이가 크다. starter-template-game 검수 캡처와 slot-defense 검수 캡처에서 모두 같은 인상이었다.

| 구분 | 내용 |
|---|---|
| 포함 | 1) 같은 홈 화면(세로 390x844, hero 프로필)으로 그린 질감 시안 3안을 만들어 사용자가 1안을 고른다. 2) 고른 방향의 UI 기준 crop을 anchor로 두고 `game-asset-pipeline`으로 9분할 스킨 8장(primary 3상태, secondary 2상태, panel, popup_frame, chip)을 PNG로 생성해 `skins/soft_adventure/`의 svg를 대체한다(`skin.json` textures만 바뀜, 계약 1.1.0 유지). 3) 아이콘 7종(coin, account, shop, inbox, ads, operations, settings)을 같은 화풍으로 생성한다. 4) `juice.gd`에 상시 모션 프리셋 `idle_pulse`(주 버튼 숨쉬기), `float`(떠다니기), `shine`(하이라이트 스윕)을 더하고 홈 주 버튼과 재화 칩에 적용한다. 5) 생성 기록(manifest, 프롬프트, raw)을 `godot/addons/seorilabs_game/skins/soft_adventure/art/`에 남기고 원본은 NAS로 이관한다 |
| 제외 | 로고타입·타이틀 키 비주얼(제품별, DEC 대기), 캠프 가로 합성 화면 `camp.svg`(별도), 제품 스킨(slot-defense holo는 같은 파이프라인으로 후속), 효과음·파티클 추가, 마켓 출시 |

전후 예시: 홈의 Set out 버튼은 지금 금색 색면 + 갈색 선이다. 전환 뒤에는 고른 방향의 재질(예: 상단 하이라이트와 하단 그림자가 있는 금빛 나무판)로 그려지고, 숨쉬기 모션이 붙는다. 재화 칩은 같은 재질의 알약형 판에 그린 코인 아이콘이 들어간다.

## 사용자 흐름·화면 상태

흐름과 배치는 바뀌지 않는다. 바뀌는 것은 표면 텍스처와 상시 모션이다.

| 화면 | 바뀌는 것 | 상태 |
|---|---|---|
| 타이틀·홈(hero/map/world, 가로 캠프) | 버튼·패널·칩 텍스처, 아이콘, 주 버튼 숨쉬기 | 320x568, 390x844, 568x320, 844x390, ko·en, 큰 글자 |
| 모달(설정·우편·지원·계정·상점·순위) | 프레임·패널·버튼 텍스처 | reduced_motion이면 상시 모션 정지 |
| 보상 | 코인 아이콘 교체 | 3단계 연출 유지 |

## 구조·책임·의존성

- 시안: `game-asset-pipeline`(gemini-3-pro-image)로 anchor = 기존 키 비주얼 `reference/assets/soft-adventure.png`, 구성 참조 = 현재 홈 캡처. 생성 이미지의 글자는 쓰지 않고(라벨 공백) 실제 서체 레이어로 보정해 비교한다(`game-ui-design` 2절).
- 스킨 생성: 고른 시안에서 UI 기준 crop을 추출해 `skins/soft_adventure/art/style/ui-reference.png`로 두고, `asset-manifest.json`의 `final_canvas: preserve-layout`로 8장을 만든다(primary 512x256, secondary 512x256, panel 512x512, popup_frame 512x512, chip 384x160). 9분할 margins는 최종 픽셀 기준으로 `skin.json`에 적는다. 모서리 장식은 margins 안, 늘어나는 구역은 균일한 띠만.
- 테마: `build_theme.gd`로 `theme.tres` 재생성. `theme_builder.texture_box`는 PNG를 그대로 받는다. svg는 지운다(`test_ui_kit.py` 참조 무결성 검사 갱신).
- 상시 모션: `juice.gd`에 static `idle_pulse(node, scale, period)`, `float(node, px, period)`, `shine(node, period)`(ColorRect 하이라이트 스윕). `Juice.reduced_motion`이면 즉시 정지. `_home`의 주 버튼과 재화 칩에 연결.
- 의존: Gemini API 키(`~/.config/seorilabs/gemini-api-key.env`), Pillow. 투명 처리에 `uvx rembg`가 필요하면 세션 venv에 설치하고 끝나면 지운다.

## 데이터·인터페이스·실패 처리

- `skin.json` 계약은 그대로다(textures 파일명과 margins만 바뀜). 소비 게임은 새 묶음을 설치하면 외형이 바뀌고, 제품 스킨(`skin_dir`)을 쓰는 게임은 영향이 없다.
- 생성 실패·스타일 이탈은 `--only <name> --force`로 재생성한다. 9분할 이음매가 늘어나는 구역에서 깨지면 margins를 늘리거나 재생성한다.
- 상시 모션은 Tween 루프라 화면 전환 시 `_clear`에서 kill한다.

## 품질 요구사항

- `ui_gate.py` 8항목 PASS(painted_skin은 StyleBoxTexture 계수라 그대로 통과).
- 3크기(320x568, 390x844, 844x390)에서 9분할 이음매·줄무늬·모서리 왜곡 없음, 큰 글자 설정(기반은 모든 역할 +3px)에서 글자가 스킨 밖으로 나가지 않음.
- 선택한 시안과 실행 화면의 재질·색·구도가 같다(`game-ui-design/references/runtime-review.md` 비교 기록).

## 대안·주요 결정

| 대안 | 결정 |
|---|---|
| svg를 더 정교하게 그린다(그라데이션·하이라이트) | 보조로만. 벡터로는 그린 질감(붓 터치, 재질)이 나오지 않아 상용 느낌의 핵심이 빠진다 |
| 제품마다 처음부터 그린다 | 기본 스킨을 먼저 올려 새 게임 전부가 받게 하고, 제품은 같은 파이프라인으로 자기 방향을 만든다 |
| 시안 없이 바로 스킨 생성 | 기각. 제품 정책의 사용자 시안 선택을 따른다. 시안 3안은 같은 화면·같은 정보·같은 비율로 만든다 |
| 상시 모션을 이번에 뺀다 | 기각. 정지된 화면이 "앱처럼" 보이는 두 번째 원인이고 킷 변경이 작다 |

## 인수조건·테스트·검수

| 조건 ID | 관찰할 동작·통과 기준 | 테스트 방법·환경 | 격리 데이터 | 기대 결과 | 증거 |
|---|---|---|---|---|---|
| AC-1 | 시안 3안이 같은 화면·정보·비율이고 사용자가 1안을 고른 기록이 있다 | 시안 이미지, 선택 메시지 | — | 선택 기록 | 설계 승인 절 |
| AC-2 | 스킨 8장이 PNG 9분할로 `skin.json`에 등록되고 `theme.tres`가 재생성된다. `test_ui_kit.py` 통과 | `npm test` | — | 통과 | CI |
| AC-3 | 3크기 캡처에서 이음매·줄무늬·모서리 왜곡 없음, 150%에서 넘침 없음 | `check.py --capture` 320x568·390x844·844x390, 큰 글자 캡처 | 격리 저장 | 통과 | 캡처 |
| AC-4 | 홈 주 버튼 `idle_pulse`, 재화 칩 `float`가 돌고 reduced_motion이면 정지. 화면 전환 시 Tween이 남지 않는다 | `ui_kit_probe` | — | PASS | ui-kit.json |
| AC-5 | 아이콘 7종이 같은 화풍이고 콘택트 시트 검수 통과 | `qa_contact_sheet.py` | — | 통과 | 시트 이미지 |
| AC-6 | 선택한 시안과 실행 홈 화면 비교 기록(구도·재질·색) | `runtime-review.md` 양식 | — | 차이 없음 또는 수정 완료 | 비교 기록 |
| AC-7 | 독립 검수 3회(모든 기능, 기능·UX) 통과 | 다른 에이전트, 390x844·320x568·844x390 | 격리 저장 | pass 3회 | `docs/qa/ui-kit-painted-review/round-{1..3}.md` |

- TDD: `ui_kit_probe`의 상시 모션 검사(프리셋 호출 뒤 scale·position이 주기 안에서 변하고 reduced_motion이면 변하지 않음)는 구현 전 FAIL. `test_ui_kit.py`의 텍스처 참조 검사는 PNG 교체 뒤 통과.
- 테스트 계획: [test-plan.json](test-plan.json). L3(공통 묶음 `addons/**`), 개발 환경, redesign true(공통 화면 외형 개편, 독립 검수 3회), 출시 없음.

## 적용·운영·되돌리기

1. 시안 3안 → 사용자 선택 → UI 기준 crop·style guide → 스킨 8장·아이콘 7종 생성·콘택트 시트 → `skin.json`·`theme.tres` → 상시 모션 프리셋·probe → `npm test`·캡처 → 런타임 비교 → 독립 검수 3회 → PR → 잠금 후속 PR → 소비 게임(starter)은 새 묶음 설치.
2. 되돌리기: PR revert. svg 원본은 git 이력에 남는다.
3. 비용: gemini-3-pro-image 기준 시안 3장 + 스킨 8장 + 아이콘 7장 + 재생성 여유 ≈ 25장, 약 4달러.
4. 남은 위험: 생성 9분할의 늘어나는 구역에 붓 질감이 들어가면 줄무늬가 생긴다. 프롬프트에 "늘어나는 구역은 균일한 띠"를 넣고 큰 크기 캡처로 검사한다.

## 검수 결과와 후속

- 1차 후보 `10a8765` 1~3회차 fail(프로브의 삭제된 svg 경로, 낮은 행에서 눌리는 패널, 320 폭 제목 꺾임, 캠프 탭, 리벳 늘어남, 투명 여백, 숨쉬기 축) → 텍스처 축소·투명 여백 제거·RowPanel·타일 축·pivot 보정. 2차 후보 `f710bbd` 4~6회차 pass. 기록 `docs/qa/ui-kit-painted-review/round-1..6.md`.
- 후속(낮음): 팝업 프레임을 세로·가로 tile로 반복하면서 가운데 나뭇결 면과 위·아래 띠의 타일 경계가 보인다(4·5회차 N1). 띠 텍스처 가장자리 끈 제거와 가운데 면 좌우 밝기 맞춤으로 재생성한다. 생성 manifest의 `final_canvas`가 잘라내기 전 크기라 재생성 시 margins와 어긋난다(6회차 D11). 다음 재생성 때 잘라낸 크기와 잘라내기 단계를 manifest에 기록한다.

## v2 후속 보정(2026-11-06, 사용자 지시 "남은 후속 결함도 해결해")

| 결함 | 원인 | 보정 |
|---|---|---|
| 팝업 프레임 타일 경계에 가죽 끈 두 개가 맞붙고 나뭇결 면에 세로 밝기 단차가 보임(4·5회차 N1) | 9분할 경계(44px) 안쪽에 끈이 있어 반복 구간 양 끝에 끈이 들어갔고, 구간 끝과 시작의 픽셀이 이어지지 않았다 | 경계를 끈 바깥(62px)으로 옮기고 `tools/skin_postprocess.py`의 `tileable`로 구간 시작을 구간 끝 너머 픽셀과, 모서리 조각 끝을 구간 끝과 섞는다. 축은 `tile_fit`(정수 반복)으로 바꿔 마지막 타일이 잘리지 않게 한다. 재화 칩도 같은 처리 |
| 생성 manifest의 최종 크기가 잘라내기 전 값이라 재생성 시 margins와 어긋남(6회차 D11) | 후처리 단계(크로마키, 자르기, 투명 여백 자르기)를 손으로 했고 기록하지 않았다 | 후처리를 `tools/skin_postprocess.py`로 옮기고 manifest에 실제 최종 크기와 `postprocess` 순서를 적는다. NAS raw로 돌리면 버튼과 아이콘이 커밋된 파일과 픽셀이 같다. `test_ui_kit.py`가 manifest 타일 margins와 skin.json margins 일치를 검사한다 |
| UI 기준 crop(1.5MB)과 생성 기록이 공통 묶음에 들어감 | `art/`가 묶음 ROOTS 안에 있었다 | 저장소 루트 `art/skins/soft_adventure/`로 옮긴다. 묶음에 설치되지 않는다 |
| 568x320 캠프 홈에서 긴 재화 문자열로 칩이 0.66배로 줄면 (+) 터치 영역이 37px(starter 9회차 N-3) | 칩 전체를 scale로 줄였다 | 숫자 글자를 12px까지 먼저 줄이고, 그래도 넘칠 때만 칩을 줄이되 (+)가 44px 아래로 내려가지 않게 한다. `camp_probe`가 (+) 크기를 검사한다 |

| starter-template-game 여정이 844x390·667x375·812x375·960x540에서 `check deletion status` 단계 실패(기존 문제, starter #23 설계) | 배율 1.22에서 버튼 높이가 68.25px라 스크롤 끝에서도 0.25px 넘쳤고, E2E 드라이버가 이를 가려짐으로 보고 더 스크롤할 수 없어 실패했다 | `tests/common/e2e_driver.gd`가 0.5px 미만 넘침을 보이는 것으로 본다(1px은 계속 가려짐). `e2e_scroll_probe`에 0.25px 넘침 버튼 탭 검사 |
| 가로 전용 게임이 세로 창(390x844, 웹 세로 화면)에서 제목이 1425px로 부풀고 Collect 버튼이 화면 밖(같은 기존 문제) | `_ui_scale`이 가로 모드에서 높이/320만 봐서 2.6배가 됐다 | 너비/568과 높이/320 중 작은 값을 쓴다. 16:9 이상 가로 화면에서는 값이 같다 |

테스트 계획은 v1과 같다(L3 dev, release null). 외형 변화가 팝업 프레임 테두리·칩 타일 경계에 한정된 보정이라 독립 검수는 바뀐 표면을 중심으로 1회 돌린다.

## 승인·추적

- 사용자가 2026-11-06 "제안 작업 좋다"로 작업을 승인하고, 같은 날 시안 A 나무·가죽 어드벤처를 골랐다(B 도자기·구름, C 양피지·지도 기각). 시안 비교는 아티팩트가 아닌 로컬 파일로 보여 달라는 요청이 있었다.
